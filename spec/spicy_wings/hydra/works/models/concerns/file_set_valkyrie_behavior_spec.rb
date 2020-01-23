# frozen_string_literal: true
require 'spicy_wings_helper'
require 'spicy_wings/model_transformer'

RSpec.describe SpicyWings::Works::FileSetValkyrieBehavior, :clean_repo do
  subject(:factory) { SpicyWings::ModelTransformer.new(pcdm_object: pcdm_object) }

  let(:resource) { subject.build }

  let(:work1)    { build(:work, id: 'wk1', title: ['Work 1']) }
  let(:work2)    { build(:work, id: 'wk2', title: ['Work 2']) }
  let(:fileset1) { build(:file_set, id: 'fs1', title: ['Fileset 1']) }

  describe 'type check methods on valkyrie resource' do
    let(:pcdm_object) { fileset1 }

    it 'returns appropriate response from type check methods' do
      expect(resource.pcdm_collection?).to be false
      expect(resource.pcdm_object?).to be true
      expect(resource.collection?).to be false
      expect(resource.work?).to be false
      expect(resource.file_set?).to be true
    end
  end

  describe '#parent_works' do
    let(:pcdm_object) { fileset1 }
    let(:child_file_set_resource) { resource }

    before do
      work1.ordered_members = [fileset1]
      work2.ordered_members = [fileset1]
      work1.save!
      work2.save!
    end

    context 'when valkyrie resources requested' do
      it 'returns parent works as valkyrie resources through file_set_valkyrie_behavior' do
        resources = child_file_set_resource.parent_works(valkyrie: true)
        expect(resources.map(&:work?)).to all(be true)
        expect(resources.map(&:id)).to match_valkyrie_ids_with_active_fedora_ids([work1.id, work2.id])
      end
    end
    context 'when active fedora objects requested' do
      it 'returns parent works as fedora objects through file_set_valkyrie_behavior' do
        af_objects = child_file_set_resource.parent_works(valkyrie: false)
        expect(af_objects.map(&:work?)).to all(be true)
        expect(af_objects.map(&:id)).to match_array [work1.id, work2.id]
      end
    end
    context 'when return type is not specified' do
      it 'returns parent works as fedora objects through file_set_valkyrie_behavior' do
        af_objects = child_file_set_resource.parent_works
        expect(af_objects.map(&:work?)).to all(be true)
        expect(af_objects.map(&:id)).to match_array [work1.id, work2.id]
      end
    end
  end

  describe '#parent_work_ids' do
    let(:pcdm_object) { fileset1 }
    let(:child_file_set_resource) { resource }

    before do
      work1.ordered_members = [fileset1]
      work2.ordered_members = [fileset1]
      work1.save!
      work2.save!
    end

    context 'when valkyrie resources requested' do
      it 'returns parent works as valkyrie resources through file_set_valkyrie_behavior' do
        resource_ids = child_file_set_resource.parent_work_ids(valkyrie: true)
        expect(resource_ids).to match_valkyrie_ids_with_active_fedora_ids([work1.id, work2.id])
      end
    end
    context 'when active fedora objects requested' do
      it 'returns parent works as fedora objects through file_set_valkyrie_behavior' do
        af_object_ids = child_file_set_resource.parent_work_ids(valkyrie: false)
        expect(af_object_ids).to match_array [work1.id, work2.id]
      end
    end
    context 'when return type is not specified' do
      it 'returns parent works as fedora objects through file_set_valkyrie_behavior' do
        af_object_ids = child_file_set_resource.parent_work_ids
        expect(af_object_ids).to match_array [work1.id, work2.id]
      end
    end
  end
end
