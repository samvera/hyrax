# frozen_string_literal: true

RSpec.describe Hyrax::RedirectsFieldBehavior do
  let(:form_class) do
    Class.new do
      attr_accessor :redirects

      def self.property(*); end

      def from_hash(params)
        params
      end

      def deserialize!(params)
        from_hash(params)
      end

      include Hyrax::RedirectsFieldBehavior
      prepend Hyrax::RedirectsFieldBehavior
    end
  end

  let(:form) { form_class.new }

  before do
    allow(Hyrax.config).to receive(:redirects_enabled?).and_return(true)
    allow(Hyrax.config).to receive(:redirects_active?).and_return(true)
  end

  describe '.included' do
    let(:property_target) do
      Class.new do
        def self.property(*); end
      end
    end

    it 'is a no-op when the config gate is closed' do
      allow(Hyrax.config).to receive(:redirects_enabled?).and_return(false)
      expect(property_target).not_to receive(:property)
      property_target.include(described_class)
    end

    it 'registers the redirects_attributes virtual property when enabled' do
      expect(property_target).to receive(:property).with(
        :redirects_attributes,
        virtual: true,
        populator: :redirects_attributes_populator,
        prepopulator: :redirects_attributes_prepopulator
      )
      property_target.include(described_class)
    end
  end

  describe '#deserialize!' do
    it 'strips the renamed redirects key so the populator owns the write' do
      result = form.deserialize!('redirects' => 'overwrite-me', :redirects => 'also', 'title' => 'kept')
      expect(result).to eq('title' => 'kept')
    end

    it 'is a no-op on the renamed key when the feature is inactive' do
      allow(Hyrax.config).to receive(:redirects_active?).and_return(false)
      result = form.deserialize!('redirects' => 'kept', 'title' => 'kept')
      expect(result).to eq('redirects' => 'kept', 'title' => 'kept')
    end
  end

  describe '#redirects_attributes_populator' do
    it 'normalizes paths and produces the persisted hash shape' do
      fragment = {
        '0' => { 'path' => '  /foo/  ', 'canonical' => 'true' },
        '1' => { 'path' => '/bar', 'canonical' => 'false', 'sequence' => '5' }
      }
      form.send(:redirects_attributes_populator, fragment: fragment)

      expect(form.redirects).to eq([
                                     { 'path' => '/foo', 'canonical' => true, 'sequence' => 0 },
                                     { 'path' => '/bar', 'canonical' => false, 'sequence' => 5 }
                                   ])
    end

    it 'drops rows marked for destruction' do
      fragment = {
        '0' => { 'path' => '/keep', 'canonical' => 'false' },
        '1' => { 'path' => '/drop', 'canonical' => 'false', '_destroy' => 'true' }
      }
      form.send(:redirects_attributes_populator, fragment: fragment)

      expect(form.redirects.map { |e| e['path'] }).to eq(['/keep'])
    end

    it 'drops rows with a blank path' do
      fragment = {
        '0' => { 'path' => '/keep', 'canonical' => 'false' },
        '1' => { 'path' => '   ', 'canonical' => 'false' }
      }
      form.send(:redirects_attributes_populator, fragment: fragment)

      expect(form.redirects.map { |e| e['path'] }).to eq(['/keep'])
    end

    it 'is a no-op when the feature is inactive' do
      allow(Hyrax.config).to receive(:redirects_active?).and_return(false)
      form.redirects = 'untouched'
      form.send(:redirects_attributes_populator, fragment: { '0' => { 'path' => '/foo' } })

      expect(form.redirects).to eq('untouched')
    end
  end

  describe '#redirects_attributes_prepopulator' do
    it 'wraps each persisted hash entry in a Hyrax::Redirect presenter' do
      form.redirects = [{ 'path' => '/foo', 'canonical' => true, 'sequence' => 0 }]
      form.send(:redirects_attributes_prepopulator)

      expect(form.redirects.first).to be_a(Hyrax::Redirect)
      expect(form.redirects.first.path).to eq('/foo')
      expect(form.redirects.first.canonical).to be(true)
    end

    it 'is a no-op when the feature is inactive' do
      allow(Hyrax.config).to receive(:redirects_active?).and_return(false)
      original = [{ 'path' => '/foo' }]
      form.redirects = original
      form.send(:redirects_attributes_prepopulator)

      expect(form.redirects).to be(original)
    end
  end
end
