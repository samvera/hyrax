# frozen_string_literal: true
require 'wings_helper'
require 'wings/model_transformer'

RSpec.describe Wings::CollectionBehavior do
  subject(:factory) { Wings::ModelTransformer.new(pcdm_object: pcdm_object) }

  let(:resource) { subject.build }

  let(:collection1) { create(:public_collection_lw, title: ['Collection 1']) }
  let(:collection2) { create(:public_collection_lw, title: ['Collection 2']) }
  let(:collection3) { create(:public_collection_lw, title: ['Collection 3']) }
  let(:work1)       { create(:work, title: ['Work 1']) }
  let(:work2)       { create(:work, title: ['Work 2']) }
  let(:work3)       { build(:work, title: ['Work 3']) }
  let(:fileset1)    { build(:file_set, title: ['Fileset 1']) }
  let(:fileset2)    { build(:file_set, title: ['Fileset 2']) }

  describe '#add_collections_and_works' do
    let(:pcdm_object) { collection1 }
    let(:parent_collection_resource) { resource }

    context 'when new_member_ids are valkyrie ids' do
      let(:collection_resource2) { Wings::ModelTransformer.new(pcdm_object: collection2).build }
      let(:collection_resource3) { Wings::ModelTransformer.new(pcdm_object: collection3).build }
      let(:work_resource1) { Wings::ModelTransformer.new(pcdm_object: work1).build }
      let(:work_resource2) { Wings::ModelTransformer.new(pcdm_object: work2).build }

      it 'adds the collections and works to the parent collection' do
        valkyrie_ids = [collection_resource2.id, collection_resource3.id, work_resource1.id, work_resource2.id]
        parent_collection_resource.add_collections_and_works(valkyrie_ids, valkyrie: true)

        resources = parent_collection_resource.child_collections_and_works(valkyrie: true)
        expect(resources.map(&:id)).to match_valkyrie_ids_with_active_fedora_ids([collection2.id, collection3.id, work1.id, work2.id])
      end
    end

    context 'when new_member_ids are active fedora ids' do
      it 'adds the collections and works to the parent collection' do
        af_ids = [collection2.id, collection3.id, work1.id, work2.id]
        parent_collection_resource.add_collections_and_works(af_ids, valkyrie: false)

        resources = parent_collection_resource.child_collections_and_works(valkyrie: true)
        expect(resources.map(&:id)).to match_valkyrie_ids_with_active_fedora_ids([collection2.id, collection3.id, work1.id, work2.id])
      end
    end
  end

  describe '#child_collections_and_works' do
    let(:pcdm_object) { collection1 }
    let(:parent_collection_resource) { resource }

    before do
      collection2.member_of_collections = [collection1]
      collection3.member_of_collections = [collection1]
      work1.member_of_collections = [collection1]
      work2.member_of_collections = [collection1]
      collection2.save!
      collection3.save!
      work1.save!
      work2.save!
      collection1.save!
    end

    context 'when valkyrie resources requested' do
      it 'returns parent collections as valkyrie resources through pcdm_valkyrie_behavior' do
        resources = parent_collection_resource.child_collections_and_works(valkyrie: true)
        expect(resources.map(&:id)).to match_valkyrie_ids_with_active_fedora_ids([collection2.id, collection3.id, work1.id, work2.id])
      end
    end
    context 'when active fedora objects requested' do
      it 'returns parent collections as fedora objects through pcdm_valkyrie_behavior' do
        af_objects = parent_collection_resource.child_collections_and_works(valkyrie: false)
        expect(af_objects.map(&:id)).to match_array [collection2.id, collection3.id, work1.id, work2.id]
      end
    end
    context 'when return type is not specified' do
      it 'returns parent collections as fedora objects through pcdm_valkyrie_behavior' do
        af_objects = parent_collection_resource.child_collections_and_works
        expect(af_objects.map(&:id)).to match_array [collection2.id, collection3.id, work1.id, work2.id]
      end
    end
  end

  describe '#child_collections_and_works_ids' do
    let(:pcdm_object) { collection1 }
    let(:parent_collection_resource) { resource }

    before do
      collection2.member_of_collections = [collection1]
      collection3.member_of_collections = [collection1]
      work1.member_of_collections = [collection1]
      work2.member_of_collections = [collection1]
      collection2.save!
      collection3.save!
      work1.save!
      work2.save!
      collection1.save!
    end

    context 'when valkyrie resources requested' do
      it 'returns ids of works only as valkyrie resources through pcdm_valkyrie_behavior' do
        resource_ids = parent_collection_resource.child_collections_and_works_ids(valkyrie: true)
        expect(resource_ids).to match_valkyrie_ids_with_active_fedora_ids([work1.id, work2.id, collection2.id, collection3.id])
      end
    end
    context 'when active fedora objects requested' do
      it 'returns ids of works only as fedora objects through pcdm_valkyrie_behavior' do
        af_object_ids = parent_collection_resource.child_collections_and_works_ids(valkyrie: false)
        expect(af_object_ids.to_a).to match_array [work1.id, work2.id, collection2.id, collection3.id]
      end
    end
    context 'when return type is not specified' do
      it 'returns ids of works only as fedora objects through pcdm_valkyrie_behavior' do
        af_object_ids = parent_collection_resource.child_collections_and_works_ids
        expect(af_object_ids.to_a).to match_array [work1.id, work2.id, collection2.id, collection3.id]
      end
    end
  end
end
