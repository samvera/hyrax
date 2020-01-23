# frozen_string_literal: true
require 'spicy_wings_helper'
require 'spicy_wings/model_transformer'

RSpec.describe SpicyWings::Pcdm::ObjectValkyrieBehavior, :clean_repo do
  subject(:factory) { SpicyWings::ModelTransformer.new(pcdm_object: pcdm_object) }

  let(:work1)       { build(:work, id: 'wk1', title: ['Work 1']) }

  describe 'type check methods on valkyrie resource' do
    let(:pcdm_object) { work1 }
    let(:resource) { subject.build }

    it 'returns appropriate response from type check methods' do
      expect(resource.pcdm_collection?).to be false
      expect(resource.pcdm_object?).to be true
    end
  end
end
