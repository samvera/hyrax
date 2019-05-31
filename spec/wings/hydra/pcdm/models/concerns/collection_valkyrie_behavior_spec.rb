# frozen_string_literal: true
require 'wings_helper'
require 'wings/model_transformer'

RSpec.describe Wings::Pcdm::CollectionValkyrieBehavior, :clean_repo do
  subject(:factory) { Wings::ModelTransformer.new(pcdm_object: pcdm_object) }

  let(:collection1) { build(:public_collection_lw, id: 'col1', title: ['Collection 1']) }
  let(:collection2) { build(:public_collection_lw, id: 'col2', title: ['Collection 2']) }
  let(:collection3) { build(:public_collection_lw, id: 'col3', title: ['Collection 3']) }
  let(:pcdm_object) { collection1 }
  let(:resource) { subject.build }

  before do
    collection2.member_of_collections = [collection1]
    collection2.save!
    collection3.member_of_collections = [collection1]
    collection3.save!
  end

  describe 'type check methods on valkyrie resource' do
    it { expect(resource.pcdm_collection?).to be true }
    it { expect(resource.pcdm_object?).to be false }
  end

  describe '#collection_ids' do
    it { expect(resource.collection_ids).to eq([collection2.id, collection3.id]) }
  end

  describe '#collections' do
    it { expect(resource.collections).to eq([collection2, collection3]) }
  end

  describe '#ordered_collection_ids' do
    it { expect(resource.ordered_collection_ids).to eq([collection2.id, collection3.id]) }
  end

  describe '#ordered_collections' do
    it { expect(resource.ordered_collections).to eq([collection2, collection3]) }
  end
end
