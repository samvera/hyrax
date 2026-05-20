# frozen_string_literal: true

RSpec.describe Hyrax::RedirectsNormalization do
  let(:resource_class) do
    Class.new(Valkyrie::Resource) do
      attribute :redirects, Valkyrie::Types::Array.of(Valkyrie::Types::Hash)
      include Hyrax::RedirectsNormalization
    end
  end

  let(:resource) { resource_class.new }

  describe 'normalization on write' do
    it 'strips trailing slashes' do
      resource.redirects = [{ 'path' => '/foo/' }]
      expect(resource.redirects.first['path']).to eq('/foo')
    end

    it 'adds a leading slash' do
      resource.redirects = [{ 'path' => 'handle/123' }]
      expect(resource.redirects.first['path']).to eq('/handle/123')
    end

    it 'extracts path from a full URL with query string' do
      resource.redirects = [{ 'path' => 'https://old.example.edu/handle/123?utm=email' }]
      expect(resource.redirects.first['path']).to eq('/handle/123')
    end

    it 'accepts symbol keys' do
      resource.redirects = [{ path: '/foo/' }]
      expect(resource.redirects.first[:path]).to eq('/foo')
    end

    it 'preserves non-path keys on the entry' do
      resource.redirects = [{ 'path' => '/foo/', 'display_url' => true }]
      entry = resource.redirects.first
      expect(entry['path']).to eq('/foo')
      expect(entry['display_url']).to be true
    end

    it 'normalizes every entry in a multi-entry array' do
      resource.redirects = [{ 'path' => '/foo/' }, { 'path' => 'bar' }]
      expect(resource.redirects.map { |e| e['path'] }).to eq(['/foo', '/bar'])
    end

    it 'is idempotent — re-assigning normalized values is a no-op' do
      resource.redirects = [{ 'path' => '/foo/' }]
      first = resource.redirects
      resource.redirects = first
      expect(resource.redirects).to eq(first)
    end

    it 'leaves non-redirects attributes untouched' do
      other_class = Class.new(Valkyrie::Resource) do
        attribute :title, Valkyrie::Types::String
        attribute :redirects, Valkyrie::Types::Array.of(Valkyrie::Types::Hash)
        include Hyrax::RedirectsNormalization
      end
      r = other_class.new(title: 'A title that ends with /')
      expect(r.title).to eq('A title that ends with /')
    end
  end

  describe 'flex-mode behavior (m3 singleton-class setter)' do
    let(:flex_class) do
      Class.new(Valkyrie::Resource) do
        include Hyrax::Flexibility
        attribute :redirects, Valkyrie::Types::Array.of(Valkyrie::Types::Hash)
        include Hyrax::RedirectsNormalization
      end
    end

    it 'fires under the flex singleton-class setter path' do
      # Mirrors how Hyrax::Flexibility.load attaches the schema to the
      # singleton class before set_value is called.
      resource = flex_class.allocate
      resource.send(:initialize, {})
      resource.singleton_class.attributes(redirects: Valkyrie::Types::Array.of(Valkyrie::Types::Hash))

      resource.set_value(:redirects, [{ 'path' => '/foo/' }])

      expect(resource.redirects.first['path']).to eq('/foo')
    end
  end
end
