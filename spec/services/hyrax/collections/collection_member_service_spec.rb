# frozen_string_literal: true
RSpec.describe Hyrax::Collections::CollectionMemberService, clean_repo: true do
  let(:blacklight_config) { CatalogController.blacklight_config }
  let(:repository) { Blacklight::Solr::Repository.new(blacklight_config) }
  let(:current_ability) { instance_double(Ability, admin?: true) }
  let!(:nestable_collection) { create(:public_collection_lw, collection_type_settings: [:nestable]) }
  let(:scope) { double('Scope', current_ability: current_ability, repository: repository, blacklight_config: blacklight_config, collection: nestable_collection) }
  let!(:subcollection) { create(:public_collection_lw, member_of_collections: [nestable_collection], collection_type_settings: [:nestable]) }
  let(:builder) { described_class.new(scope: scope, collection: nestable_collection, params: { "id" => nestable_collection.id.to_s }) }

  let!(:work1) { create(:generic_work, member_of_collections: [nestable_collection]) }
  let!(:work2) { create(:generic_work) }
  let!(:work3) { create(:generic_work, member_of_collections: [nestable_collection]) }

  describe '#available_member_subcollections' do
    let(:subject) { builder.available_member_subcollections }
    let(:ids) { subject.response[:docs].map { |col| col[:id] } }

    it 'returns the members that are collections' do
      expect(ids).to include(subcollection.id)
      expect(ids).not_to include(work1.id)
      expect(ids).not_to include(work3.id)
      expect(ids).not_to include(work2.id)
    end
  end

  describe '#available_member_works' do
    let(:subject) { builder.available_member_works }
    let(:ids) { subject.response[:docs].map { |col| col[:id] } }

    it 'returns the members that are collections' do
      expect(ids).to include(work1.id)
      expect(ids).to include(work3.id)
      expect(ids).not_to include(work2.id)
      expect(ids).not_to include(subcollection.id)
    end
  end

  describe '#available_member_work_ids' do
    let(:subject) { builder.available_member_work_ids }
    let(:ids) { subject.response[:docs].map { |col| col[:id] } }

    it 'returns the members ids that are works' do
      expect(ids).to include(work1.id)
      expect(ids).to include(work3.id)
      expect(ids).not_to include(work2.id)
      expect(ids).not_to include(subcollection.id)
    end
  end
end
