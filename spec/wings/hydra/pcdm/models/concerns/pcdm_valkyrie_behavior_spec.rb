# frozen_string_literal: true
require 'wings_helper'
require 'wings/model_transformer'

RSpec.describe Wings::Pcdm::PcdmValkyrieBehavior do
  subject(:factory) { Wings::ModelTransformer.new(pcdm_object: pcdm_object) }

  let(:resource) { subject.build }

  let(:collection1) { build(:public_collection_lw, id: 'col1', title: ['Collection 1']) }
  let(:collection2) { build(:public_collection_lw, id: 'col2', title: ['Collection 2']) }
  let(:collection3) { build(:public_collection_lw, id: 'col3', title: ['Collection 3']) }
  let(:work1)       { build(:work, id: 'wk1', title: ['Work 1']) }
  let(:work2)       { build(:work, id: 'wk2', title: ['Work 2']) }
  let(:work3)       { build(:work, id: 'wk3', title: ['Work 3']) }
  let(:fileset1)    { build(:file_set, id: 'fs1', title: ['Fileset 1']) }
  let(:fileset2)    { build(:file_set, id: 'fs2', title: ['Fileset 2']) }

  describe '#parent_collections' do
    let(:pcdm_object) { collection1 }
    let(:child_collection_resource) { resource }

    before do
      collection1.member_of_collections = [collection2, collection3]
      collection1.save!
    end

    context 'when valkyrie resources requested' do
      it 'returns parent collections as valkyrie resources through pcdm_valkyrie_behavior' do
        resources = child_collection_resource.parent_collections(valkyrie: true)
        expect(resources.first.pcdm_collection?).to be true
        expect(resources.map(&:id)).to match_valkyrie_ids_with_active_fedora_ids([collection2.id, collection3.id])
      end
    end
    context 'when active fedora objects requested' do
      it 'returns parent collections as fedora objects through pcdm_valkyrie_behavior' do
        af_objects = child_collection_resource.parent_collections(valkyrie: false)
        expect(af_objects.first.pcdm_collection?).to be true
        expect(af_objects.map(&:id)).to match_array [collection2.id, collection3.id]
      end
    end
    context 'when return type is not specified' do
      it 'returns parent collections as fedora objects through pcdm_valkyrie_behavior' do
        af_objects = child_collection_resource.parent_collections
        expect(af_objects.first.pcdm_collection?).to be true
        expect(af_objects.map(&:id)).to match_array [collection2.id, collection3.id]
      end
    end
  end

  describe '#parent_collection_ids' do
    let(:pcdm_object) { collection1 }
    let(:child_collection_resource) { resource }

    before do
      collection1.member_of_collections = [collection2, collection3]
      collection1.save!
    end

    context 'when valkyrie resources requested' do
      it 'returns ids of parent collections as valkyrie resources through pcdm_valkyrie_behavior' do
        resource_ids = child_collection_resource.parent_collection_ids(valkyrie: true)
        expect(resource_ids).to match_valkyrie_ids_with_active_fedora_ids([collection2.id, collection3.id])
      end
    end
    context 'when active fedora objects requested' do
      it 'returns ids of parent collections as fedora objects through pcdm_valkyrie_behavior' do
        af_object_ids = child_collection_resource.parent_collection_ids(valkyrie: false)
        expect(af_object_ids.to_a).to match_array [collection2.id, collection3.id]
      end
    end
    context 'when return type is not specified' do
      it 'returns ids of parent collections as fedora objects through pcdm_valkyrie_behavior' do
        af_object_ids = child_collection_resource.parent_collection_ids
        expect(af_object_ids.to_a).to match_array [collection2.id, collection3.id]
      end
    end
  end

  describe '#members' do
    let(:pcdm_object) { work1 }
    let(:parent_work_resource) { resource }

    before do
      work1.members = [work2, work3, fileset1, fileset2]
      work1.save!
    end

    context 'when valkyrie resources requested' do
      it 'returns parent collections as valkyrie resources through pcdm_valkyrie_behavior' do
        resources = parent_work_resource.members(valkyrie: true)
        expect(resources.map(&:id)).to match_valkyrie_ids_with_active_fedora_ids([work2.id, work3.id, fileset1.id, fileset2.id])
      end
    end
    context 'when active fedora objects requested' do
      it 'returns parent collections as fedora objects through pcdm_valkyrie_behavior' do
        af_objects = parent_work_resource.members(valkyrie: false)
        expect(af_objects.map(&:id)).to match_array [work2.id, work3.id, fileset1.id, fileset2.id]
      end
    end
    context 'when return type is not specified' do
      it 'returns parent collections as fedora objects through pcdm_valkyrie_behavior' do
        af_objects = parent_work_resource.members
        expect(af_objects.map(&:id)).to match_array [work2.id, work3.id, fileset1.id, fileset2.id]
      end
    end
  end

  describe '#member_ids' do
    let(:pcdm_object) { work1 }
    let(:parent_work_resource) { resource }

    before do
      work1.members = [work2, work3, fileset1, fileset2]
      work1.save!
    end

    # TODO: For now, the tests confirm that the correct members are returned and that they all have valkyrie ids.
    #       This is because #member_ids comes from the attribute definition and can't receive a `valkyrie:` parameter.
    context 'when valkyrie resources requested' do
      it 'returns ids of parent collections as valkyrie resources through pcdm_valkyrie_behavior' do
        resource_ids = parent_work_resource.member_ids
        expect(resource_ids).to match_valkyrie_ids_with_active_fedora_ids([work2.id, work3.id, fileset1.id, fileset2.id])
      end
    end
    # context 'when valkyrie resources requested' do
    #   it 'returns ids of parent collections as valkyrie resources through pcdm_valkyrie_behavior' do
    #     resource_ids = parent_work_resource.member_ids(valkyrie: true)
    #     expect(resource_ids).to match_valkyrie_ids_with_active_fedora_ids([work2.id, work3.id, fileset1.id, fileset2.id])
    #   end
    # end
    # context 'when active fedora objects requested' do
    #   it 'returns ids of parent collections as fedora objects through pcdm_valkyrie_behavior' do
    #     af_object_ids = parent_work_resource.member_ids(valkyrie: false)
    #     expect(af_object_ids.to_a).to match_array [work2.id, work3.id, fileset1.id, fileset2.id]
    #   end
    # end
    # context 'when return type is not specified' do
    #   it 'returns ids of parent collections as fedora objects through pcdm_valkyrie_behavior' do
    #     af_object_ids = parent_work_resource.member_ids
    #     expect(af_object_ids.to_a).to match_array [work2.id, work3.id, fileset1.id, fileset2.id]
    #   end
    # end
  end

  describe '#objects' do
    let(:pcdm_object) { collection1 }

    before do
      collection1.members = [work1, work2, collection2, collection3]
      collection1.save!
    end

    context 'when valkyrie resources requested' do
      it 'returns works only as valkyrie resources through pcdm_valkyrie_behavior' do
        resources = resource.objects(valkyrie: true)
        expect(resources.size).to eq 2
        expect(resources.first.pcdm_object?).to be true
        expect(resources.map(&:id)).to match_valkyrie_ids_with_active_fedora_ids([work1.id, work2.id])
      end
    end
    context 'when active fedora objects requested' do
      it 'returns works only as fedora objects through pcdm_valkyrie_behavior' do
        af_objects = resource.objects(valkyrie: false)
        expect(af_objects.size).to eq 2
        expect(af_objects.first.pcdm_object?).to be true
        expect(af_objects.map(&:id)).to match_array [work1.id, work2.id]
      end
    end
    context 'when return type is not specified' do
      it 'returns works only as fedora objects through pcdm_valkyrie_behavior' do
        af_objects = resource.objects
        expect(af_objects.size).to eq 2
        expect(af_objects.first.pcdm_object?).to be true
        expect(af_objects.map(&:id)).to match_array [work1.id, work2.id]
      end
    end
  end

  describe '#object_ids' do
    let(:pcdm_object) { collection1 }

    before do
      collection1.members = [work1, work2, collection2, collection3]
      collection1.save!
    end

    context 'when valkyrie resources requested' do
      it 'returns ids of works only as valkyrie resources through pcdm_valkyrie_behavior' do
        resource_ids = resource.object_ids(valkyrie: true)
        expect(resource_ids.size).to eq 2
        expect(resource_ids).to match_valkyrie_ids_with_active_fedora_ids([work1.id, work2.id])
      end
    end
    context 'when active fedora objects requested' do
      it 'returns ids of works only as fedora objects through pcdm_valkyrie_behavior' do
        af_object_ids = resource.object_ids(valkyrie: false)
        expect(af_object_ids.size).to eq 2
        expect(af_object_ids.to_a).to match_array [work1.id, work2.id]
      end
    end
    context 'when return type is not specified' do
      it 'returns ids of works only as fedora objects through pcdm_valkyrie_behavior' do
        af_object_ids = resource.object_ids
        expect(af_object_ids.size).to eq 2
        expect(af_object_ids.to_a).to match_array [work1.id, work2.id]
      end
    end
  end
end
