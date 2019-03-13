# frozen_string_literal: true
require 'wings_helper'
require 'wings/model_transformer'

RSpec.describe Wings::Works::FileSetValkyrieBehavior do
  subject(:factory) { Wings::ModelTransformer.new(pcdm_object: pcdm_object) }

  let(:fileset1) { build(:file_set, id: 'fs1', title: ['Fileset 1']) }

  describe 'type check methods on valkyrie resource' do
    let(:pcdm_object) { fileset1 }
    let(:resource) { subject.build }

    it 'returns appropriate response from type check methods' do
      expect(resource.pcdm_collection?).to be false
      expect(resource.pcdm_object?).to be true
      expect(resource.collection?).to be false
      expect(resource.work?).to be false
      expect(resource.file_set?).to be true
    end
  end
end
