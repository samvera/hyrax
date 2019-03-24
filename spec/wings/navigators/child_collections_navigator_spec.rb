# frozen_string_literal: true
require 'wings_helper'
require 'wings/model_transformer'
require 'wings/navigators/child_collections_navigator'

RSpec.describe Wings::ChildCollectionsNavigator, :clean_repo do
  subject(:factory) { Wings::ModelTransformer.new(pcdm_object: pcdm_object) }

  let(:resource) { subject.build }

  let(:adapter) { Wings::Valkyrie::MetadataAdapter.new }
  let(:query_service) { Wings::Valkyrie::QueryService.new(adapter: adapter) }
  let(:navigator) { described_class.new(query_service: query_service) }

  let(:collection1)    { build(:collection, id: 'col1', title: ['Collection 1']) }
  let(:collection2)    { build(:collection, id: 'col2', title: ['Child Collection 1']) }
  let(:collection3)    { build(:collection, id: 'col3', title: ['Child Collection 2']) }
  let(:work1) { build(:work, id: 'wk1', title: ['Child Work 1']) }
  let(:work2) { build(:work, id: 'wk2', title: ['Child Work 2']) }

  describe '#find_child_collections' do
    let(:pcdm_object) { collection1 }
    let(:collection1_resource) { resource }

    before do
      collection1.members = [collection2, collection3, work1, work2]
      collection1.save!
    end

    it 'returns only child collections as Valkyrie resources' do
      child_collections = navigator.find_child_collections(resource: collection1_resource)
      expect(child_collections.map(&:id)).to match_valkyrie_ids_with_active_fedora_ids([collection2.id, collection3.id])
    end
  end

  describe '#find_child_collection_ids' do
    let(:pcdm_object) { collection1 }
    let(:collection1_resource) { resource }

    before do
      collection1.members = [collection2, collection3, work1, work2]
      collection1.save!
    end

    it 'returns Valkyrie ids for child collections only' do
      child_collections = navigator.find_child_collections(resource: collection1_resource)
      expect(child_collections.map(&:id)).to match_valkyrie_ids_with_active_fedora_ids([collection2.id, collection3.id])
    end
  end
end
