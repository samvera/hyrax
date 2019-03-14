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

  describe '#member_ids' do
    context 'for parent collection' do
      before do
        collection1.members = [work1, work2, collection2, collection3]
        collection1.save!
      end

      let(:pcdm_object) { collection1 }

      it 'has attributes for the PCDM model' do
        expect(resource).to be_a Valkyrie::Resource
        expect(resource.member_ids).to match_valkyrie_ids_with_active_fedora_ids([work1.id, work2.id, collection2.id, collection3.id])
      end
    end

    context 'for child collection' do
      let(:pcdm_object) { collection3 }

      before do
        collection3.member_of_collections = [collection1, collection2]
        collection3.save!
      end

      it 'has attributes matching the active_fedora_object' do
        expect(resource).to be_a Valkyrie::Resource
        expect(resource.member_of_collection_ids).to match_valkyrie_ids_with_active_fedora_ids(['col1', 'col2'])
      end
    end

    context 'for work in collection' do
      let(:pcdm_object) { work1 }

      before do
        work1.member_of_collections = [collection1, collection2]
        work1.save!
      end

      it 'has attributes matching the active_fedora_object' do
        expect(resource).to be_a Valkyrie::Resource
        expect(resource.member_of_collection_ids).to match_valkyrie_ids_with_active_fedora_ids(['col1', 'col2'])
      end
    end

    context 'work with works and filesets' do
      let(:pcdm_object) { work1 }

      before do
        work1.members = [work2, work3, fileset1, fileset2]
        work1.save!
      end

      it 'has attributes matching the active_fedora_object' do
        expect(resource).to be_a Valkyrie::Resource
        expect(resource.member_ids).to match_valkyrie_ids_with_active_fedora_ids([work2.id, work3.id, fileset1.id, fileset2.id])
      end
    end
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

  describe '#object_ids on valkyrie resource' do
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
