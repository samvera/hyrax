# frozen_string_literal: true
require 'wings_helper'
require 'wings/model_transformer'

RSpec.describe Wings::Works::WorkValkyrieBehavior, :clean_repo do
  subject(:factory) { Wings::ModelTransformer.new(pcdm_object: pcdm_object) }

  let(:resource) { subject.build }

  let(:collection1) { build(:collection, id: 'col1', title: ['Collection 1']) }
  let(:collection2) { build(:collection, id: 'col2', title: ['Collection 2']) }
  let(:work1)       { build(:work, id: 'wk1', title: ['Work 1']) }
  let(:work2)       { build(:work, id: 'wk2', title: ['Child Work 1']) }
  let(:work3)       { build(:work, id: 'wk3', title: ['Child Work 2']) }
  let(:work4)       { build(:work, id: 'wk4', title: ['Parent Work 1']) }
  let(:work5)       { build(:work, id: 'wk5', title: ['Parent Work 2']) }
  let(:fileset1)    { build(:file_set, id: 'fs1', title: ['Child File Set 1']) }
  let(:fileset2)    { build(:file_set, id: 'fs2', title: ['Child File Set 2']) }

  before do
    collection1.ordered_members << work1
    collection1.save!
    collection2.ordered_members << work1
    collection2.save!
    work4.ordered_members << work1
    work4.save!
    work5.ordered_members << work1
    work5.save!
    work1.ordered_members = [work2, work3, fileset1, fileset2]
    work1.save!
    work1.reload
    expect(work1.members.map(&:id)).to contain_exactly('wk2', 'wk3', 'fs1', 'fs2')
  end

  describe 'type check methods on valkyrie resource' do
    let(:pcdm_object) { work1 }
    let(:work) { resource }

    it 'returns appropriate response from type check methods' do
      expect(work.pcdm_collection?).to be false
      expect(work.pcdm_object?).to be true
      expect(work.collection?).to be false
      expect(work.work?).to be true
      expect(work.file_set?).to be false
    end
  end

  describe '#parent_works' do
    let(:pcdm_object) { work1 }
    let(:work) { resource }

    context 'when return type is not specified' do
      it 'returns only parent works, in AF format' do
        af_objects = work.parent_works
        expect(af_objects.map(&:work?)).to all(be true)
        expect(af_objects.map(&:id)).to match_array [work4.id, work5.id]
      end
    end

    context 'when active fedora objects are requested' do
      it 'returns only parent works, in AF format' do
        af_objects = work.parent_works(valkyrie: false)
        expect(af_objects.map(&:work?)).to all(be true)
        expect(af_objects.map(&:id)).to match_array [work4.id, work5.id]
      end
    end

    context 'when valkyrie objects are requested' do
      it 'returns only parent works, in Valkyrie format' do
        resources = work.parent_works(valkyrie: true)
        expect(resources.map(&:work?)).to all(be true)
        expect(resources.map(&:id)).to match_valkyrie_ids_with_active_fedora_ids([work4.id, work5.id])
      end
    end
  end

  describe '#parent_work_ids' do
    let(:pcdm_object) { work1 }
    let(:work) { resource }

    context 'when return type is not specified' do
      it 'returns AF ids for parent works only' do
        af_object_ids = work.parent_work_ids
        expect(af_object_ids).to match_array [work4.id, work5.id]
      end
    end

    context 'when active fedora objects are requested' do
      it 'returns AF ids for parent works only' do
        af_object_ids = work.parent_work_ids(valkyrie: false)
        expect(af_object_ids).to match_array [work4.id, work5.id]
      end
    end

    context 'when valkyrie objects are requested' do
      it 'returns Valkyrie ids for parent works only' do
        resource_ids = work.parent_work_ids(valkyrie: true)
        expect(resource_ids).to match_valkyrie_ids_with_active_fedora_ids([work4.id, work5.id])
      end
    end
  end

  describe '#child_works' do
    let(:pcdm_object) { work1 }
    let(:work) { resource }

    context 'when return type is not specified' do
      it 'returns only child works, in AF format' do
        af_objects = work.child_works
        expect(af_objects.map(&:work?)).to all(be true)
        expect(af_objects.map(&:id)).to match_array [work2.id, work3.id]
      end

      context 'when operating on an unsaved work' do
        let(:pcdm_object) { build(:work, title: ['Unsaved work without children']) }
        it 'returns an empty array' do
          af_objects = work.child_works
          expect(af_objects).to match_array []
        end
      end
    end

    context 'when active fedora objects are requested' do
      it 'returns only child works, in AF format' do
        af_objects = work.child_works(valkyrie: false)
        expect(af_objects.map(&:work?)).to all(be true)
        expect(af_objects.map(&:id)).to match_array [work2.id, work3.id]
      end
    end

    context 'when valkyrie objects are requested' do
      it 'returns only child works, in Valkyrie format' do
        resources = work.child_works(valkyrie: true)
        expect(resources.map(&:work?)).to all(be true)
        expect(resources.map(&:id)).to match_valkyrie_ids_with_active_fedora_ids([work2.id, work3.id])
      end
    end
  end

  describe '#child_work_ids' do
    let(:pcdm_object) { work1 }
    let(:work) { resource }

    context 'when return type is not specified' do
      it 'returns AF ids for child works only' do
        af_object_ids = work.child_work_ids
        expect(af_object_ids).to match_array [work2.id, work3.id]
      end
    end

    context 'when active fedora objects are requested' do
      it 'returns AF ids for child works only' do
        af_object_ids = work.child_work_ids(valkyrie: false)
        expect(af_object_ids).to match_array [work2.id, work3.id]
      end
    end

    context 'when valkyrie objects are requested' do
      it 'returns Valkyrie ids for child works only' do
        resource_ids = work.child_work_ids(valkyrie: true)
        expect(resource_ids).to match_valkyrie_ids_with_active_fedora_ids([work2.id, work3.id])
      end
    end
  end

  describe '#child_file_sets' do
    let(:pcdm_object) { work1 }
    let(:work) { resource }

    context 'when return type is not specified' do
      it 'returns only child file sets, in AF format' do
        af_objects = work.child_file_sets
        expect(af_objects.map(&:file_set?)).to all(be true)
        expect(af_objects.map(&:id)).to match_array [fileset1.id, fileset2.id]
      end
    end

    context 'when active fedora objects are requested' do
      it 'returns only child file sets, in AF format' do
        af_objects = work.child_file_sets(valkyrie: false)
        expect(af_objects.map(&:file_set?)).to all(be true)
        expect(af_objects.map(&:id)).to match_array [fileset1.id, fileset2.id]
      end
    end

    context 'when valkyrie objects are requested' do
      it 'returns only child file sets, in Valkyrie format' do
        resources = work.child_file_sets(valkyrie: true)
        expect(resources.map(&:file_set?)).to all(be true)
        expect(resources.map(&:id)).to match_valkyrie_ids_with_active_fedora_ids([fileset1.id, fileset2.id])
      end
    end
  end

  describe '#child_file_set_ids' do
    let(:pcdm_object) { work1 }
    let(:work) { resource }

    context 'when return type is not specified' do
      it 'returns only child file sets, in AF format' do
        af_object_ids = work.child_file_set_ids
        expect(af_object_ids).to match_array [fileset1.id, fileset2.id]
      end
    end

    context 'when active fedora objects are requested' do
      it 'returns only child file sets, in AF format' do
        af_object_ids = work.child_file_set_ids(valkyrie: false)
        expect(af_object_ids).to match_array [fileset1.id, fileset2.id]
      end
    end

    context 'when valkyrie objects are requested' do
      it 'returns only child file sets, in Valkyrie format' do
        resource_ids = work.child_file_set_ids(valkyrie: true)
        expect(resource_ids).to match_valkyrie_ids_with_active_fedora_ids([fileset1.id, fileset2.id])
      end
    end
  end
end
