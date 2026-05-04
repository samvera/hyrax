# frozen_string_literal: true

RSpec.describe Hyrax::Indexers::RedirectsIndexer do
  let(:resource_class) do
    Class.new(Hyrax::Resource) do
      def self.name
        'TestResourceWithRedirects'
      end
      attribute :redirects, Valkyrie::Types::Array.of(Dry::Types['hash'])
    end
  end

  let(:host_indexer_class) do
    Class.new(Hyrax::Indexers::ResourceIndexer) do
      include Hyrax::Indexers::RedirectsIndexer
    end
  end

  let(:indexer) { host_indexer_class.new(resource: resource) }

  context 'with the redirects feature active' do
    before { allow(Hyrax.config).to receive(:redirects_active?).and_return(true) }

    context 'for a resource with redirects entries' do
      let(:resource) do
        resource_class.new(redirects: [
                             { 'path' => '/handle/12345/678' },
                             { 'path' => '/islandora/object/ir:1138' }
                           ])
      end

      it 'emits redirects_path_ssim with each entry path' do
        expect(indexer.to_solr['redirects_path_ssim'])
          .to contain_exactly('/handle/12345/678', '/islandora/object/ir:1138')
      end
    end

    context 'for a resource with no redirects entries' do
      let(:resource) { resource_class.new(redirects: []) }

      it 'emits redirects_path_ssim as an empty array' do
        expect(indexer.to_solr['redirects_path_ssim']).to eq([])
      end
    end

    context 'for a resource without the redirects attribute' do
      let(:bare_resource_class) do
        Class.new(Hyrax::Resource) do
          def self.name
            'TestResourceWithoutRedirects'
          end
        end
      end
      let(:resource) { bare_resource_class.new }

      it 'does not emit the redirects_path_ssim field' do
        expect(indexer.to_solr).not_to have_key('redirects_path_ssim')
      end
    end

    context 'when an entry is missing a path' do
      let(:resource) do
        resource_class.new(redirects: [
                             { 'path' => '/handle/12345/678' },
                             { 'path' => nil }
                           ])
      end

      it 'compacts nil paths out of the indexed field' do
        expect(indexer.to_solr['redirects_path_ssim'])
          .to contain_exactly('/handle/12345/678')
      end
    end
  end

  context 'with the redirects feature inactive' do
    before { allow(Hyrax.config).to receive(:redirects_active?).and_return(false) }

    let(:resource) do
      resource_class.new(redirects: [{ 'path' => '/handle/12345/678' }])
    end

    it 'does not emit redirects_path_ssim' do
      expect(indexer.to_solr).not_to have_key('redirects_path_ssim')
    end
  end
end
