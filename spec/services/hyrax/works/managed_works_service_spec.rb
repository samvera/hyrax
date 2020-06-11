# frozen_string_literal: true
RSpec.describe Hyrax::Works::ManagedWorksService, clean_repo: true do
  let(:blacklight_config) { CatalogController.blacklight_config }
  let(:repository) { Blacklight::Solr::Repository.new(blacklight_config) }

  let(:current_ability) { instance_double(Ability, admin?: true) }
  let(:scope) { double('Scope', can?: true, current_ability: current_ability, repository: repository, blacklight_config: blacklight_config) }

  describe '.managed_works_count' do
    subject { described_class.managed_works_count(scope: scope) }

    let!(:work) { create(:public_work) }

    it 'returns number of works that can be managed' do
      expect(subject).to eq(1)
    end
  end
end
