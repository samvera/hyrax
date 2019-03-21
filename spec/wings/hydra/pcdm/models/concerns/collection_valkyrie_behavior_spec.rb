# frozen_string_literal: true
require 'wings_helper'
require 'wings/model_transformer'

RSpec.describe Wings::Pcdm::CollectionValkyrieBehavior, :clean_repo do
  subject(:factory) { Wings::ModelTransformer.new(pcdm_object: pcdm_object) }

  let(:collection1) { build(:public_collection_lw, id: 'col1', title: ['Collection 1']) }

  describe 'type check methods on valkyrie resource' do
    let(:pcdm_object) { collection1 }
    let(:resource) { subject.build }

    it 'returns appropriate response from type check methods' do
      expect(resource.pcdm_collection?).to be true
      expect(resource.pcdm_object?).to be false
    end
  end
end
