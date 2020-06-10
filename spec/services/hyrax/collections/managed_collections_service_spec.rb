# frozen_string_literal: true
RSpec.describe Hyrax::Collections::ManagedCollectionsService, clean_repo: true do
  let(:blacklight_config) { CatalogController.blacklight_config }
  let(:repository) { Blacklight::Solr::Repository.new(blacklight_config) }

  let(:current_ability) { instance_double(Ability, admin?: true) }
  let(:scope) { double('Scope', can?: true, current_ability: current_ability, repository: repository, blacklight_config: blacklight_config) }

  describe '.managed_collections_count' do
    subject { described_class.managed_collections_count(scope: scope) }

    let!(:collection) { create(:public_collection) }

    it 'returns number of collections that can be managed' do
      expect(subject).to eq(1)
    end
  end
end
