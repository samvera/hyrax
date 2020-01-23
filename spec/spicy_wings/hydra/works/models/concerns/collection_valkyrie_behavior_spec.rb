# frozen_string_literal: true
require 'spicy_wings_helper'
require 'spicy_wings/model_transformer'

RSpec.describe SpicyWings::Works::CollectionValkyrieBehavior, :clean_repo do
  subject(:factory) { SpicyWings::ModelTransformer.new(pcdm_object: pcdm_object) }

  let(:collection1) { build(:public_collection_lw, id: 'col1', title: ['Collection 1']) }

  describe 'type check methods on valkyrie resource' do
    let(:pcdm_object) { collection1 }
    let(:resource) { subject.build }

    it 'returns appropriate response from type check methods' do
      expect(resource.pcdm_collection?).to be true
      expect(resource.pcdm_object?).to be false
      expect(resource.collection?).to be true
      expect(resource.work?).to be false
      expect(resource.file_set?).to be false
    end
  end
end
