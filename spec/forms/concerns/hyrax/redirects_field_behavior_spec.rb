# frozen_string_literal: true

RSpec.describe Hyrax::RedirectsFieldBehavior do
  let(:form_class) do
    Class.new do
      attr_accessor :redirects, :redirects_display_url_index

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
        populator: :redirects_attributes_populator
      )
      expect(property_target).to receive(:property).with(:redirects_display_url_index, virtual: true)
      property_target.include(described_class)
    end

    it 'does not include FormFields(:redirects) itself' do
      expect(property_target).not_to receive(:include).with(Hyrax::FormFields(:redirects))
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
        '0' => { 'path' => '  /foo/  ', 'display_url' => 'true' },
        '1' => { 'path' => '/bar', 'display_url' => 'false' }
      }
      form.send(:redirects_attributes_populator, fragment: fragment)

      expect(form.redirects).to eq([
                                     { 'path' => '/foo', 'display_url' => true },
                                     { 'path' => '/bar', 'display_url' => false }
                                   ])
    end

    it 'drops rows marked for destruction' do
      fragment = {
        '0' => { 'path' => '/keep', 'display_url' => 'false' },
        '1' => { 'path' => '/drop', 'display_url' => 'false', '_destroy' => 'true' }
      }
      form.send(:redirects_attributes_populator, fragment: fragment)

      expect(form.redirects.map { |e| e['path'] }).to eq(['/keep'])
    end

    it 'drops rows with a blank path' do
      fragment = {
        '0' => { 'path' => '/keep', 'display_url' => 'false' },
        '1' => { 'path' => '   ', 'display_url' => 'false' }
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

    context 'with redirects_display_url_index set (form radio group)' do
      let(:fragment) do
        {
          '0' => { 'path' => '/foo' },
          '1' => { 'path' => '/bar' },
          '2' => { 'path' => '/baz' }
        }
      end

      it 'marks only the selected row as display_url' do
        form.redirects_display_url_index = '1'
        form.send(:redirects_attributes_populator, fragment: fragment)

        flags = form.redirects.map { |e| [e['path'], e['display_url']] }
        expect(flags).to eq([['/foo', false], ['/bar', true], ['/baz', false]])
      end

      it 'leaves every row as display_url=false when the index is blank' do
        form.redirects_display_url_index = ''
        form.send(:redirects_attributes_populator, fragment: fragment)

        expect(form.redirects.map { |e| e['display_url'] }).to all(be false)
      end

      it 'silently ignores a selected index pointing at a row dropped for blank path' do
        form.redirects_display_url_index = '1'
        fragment_with_blank = { '0' => { 'path' => '/foo' }, '1' => { 'path' => '   ' } }
        form.send(:redirects_attributes_populator, fragment: fragment_with_blank)

        expect(form.redirects.map { |e| [e['path'], e['display_url']] }).to eq([['/foo', false]])
      end

      it 'silently ignores a selected index past the end of the fragment' do
        form.redirects_display_url_index = '99'
        form.send(:redirects_attributes_populator, fragment: fragment)

        expect(form.redirects.map { |e| e['display_url'] }).to all(be false)
      end
    end

    context 'with redirects_display_url_index nil (Bulkrax-style import path)' do
      it 'falls back to per-row display_url values' do
        form.redirects_display_url_index = nil
        fragment = {
          '0' => { 'path' => '/foo', 'display_url' => 'true' },
          '1' => { 'path' => '/bar', 'display_url' => 'false' }
        }
        form.send(:redirects_attributes_populator, fragment: fragment)

        expect(form.redirects).to eq([
                                       { 'path' => '/foo', 'display_url' => true },
                                       { 'path' => '/bar', 'display_url' => false }
                                     ])
      end
    end

    context 'when fragment is ActionController::Parameters (real form submit)' do
      it 'unwraps the params object and folds the index' do
        form.redirects_display_url_index = '1'
        params = ActionController::Parameters.new(
          '0' => { 'path' => '/foo' },
          '1' => { 'path' => '/bar' }
        )
        form.send(:redirects_attributes_populator, fragment: params)

        expect(form.redirects).to eq([
                                       { 'path' => '/foo', 'display_url' => false },
                                       { 'path' => '/bar', 'display_url' => true }
                                     ])
      end
    end
  end
end
