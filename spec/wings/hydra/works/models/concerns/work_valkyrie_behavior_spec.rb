# frozen_string_literal: true
require 'wings_helper'
require 'wings/model_transformer'

RSpec.describe Wings::Works::WorkValkyrieBehavior do
  subject(:factory) { Wings::ModelTransformer.new(pcdm_object: pcdm_object) }

  let(:work1) { build(:work, id: 'wk1', title: ['Work 1']) }

  describe 'type check methods on valkyrie resource' do
    let(:pcdm_object) { work1 }
    let(:resource) { subject.build }

    it 'returns appropriate response from type check methods' do
      expect(resource.pcdm_collection?).to be false
      expect(resource.pcdm_object?).to be true
      expect(resource.collection?).to be false
      expect(resource.work?).to be true
      expect(resource.file_set?).to be false
    end
  end
end
