# frozen_string_literal: true
require 'wings_helper'
require 'wings/model_transformer'

RSpec.describe Wings::Works::WorkValkyrieBehavior do
  subject(:factory) { Wings::ModelTransformer.new(pcdm_object: pcdm_object) }

  let(:resource) { subject.build }

  let(:work1)    { build(:work, id: 'wk1', title: ['Work 1']) }
  let(:work2)    { build(:work, id: 'wk2', title: ['Child Work 1']) }
  let(:work3)    { build(:work, id: 'wk3', title: ['Child Work 2']) }
  let(:fileset1) { build(:file_set, id: 'fs1', title: ['Child File Set 1']) }
  let(:fileset2) { build(:file_set, id: 'fs2', title: ['Child File Set 2']) }

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

  describe '#child_works' do
    let(:pcdm_object) { work1 }
    let(:work) { resource }

    before do
      work1.members = [work2, work3, fileset1, fileset2]
      work1.save!
    end

    context 'when return type is not specified' do
      it 'returns only child works, in AF format' do
        af_objects = work.child_works
        expect(af_objects.map(&:work?)).to all(be true)
        expect(af_objects.map(&:id)).to match_array [work2.id, work3.id]
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
end
