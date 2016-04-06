require 'spec_helper'

# make sure a collection by another name still assigns the @collection variable
describe OtherCollectionsController, type: :controller do
  before(:all) do
    class OtherCollection < ActiveFedora::Base
      include CurationConcerns::Collection
      property :title, predicate: ::RDF::Vocab::DC.title
    end
  end

  after(:all) do
    Object.send(:remove_const, :OtherCollection)
  end

  let(:user) { FactoryGirl.create(:user) }

  before do
    allow(controller).to receive(:has_access?).and_return(true)
    sign_in user
  end

  describe "#show" do
    let(:asset1) { create(:generic_work, user: user) }
    let(:asset2) { create(:generic_work, user: user) }
    let(:asset3) { create(:generic_work, user: user) }

    let(:collection) do
      OtherCollection.create!(title: ["My collection"]) do |collection|
        collection.apply_depositor_metadata(user.user_key)
      end
    end

    before do
      allow(controller).to receive(:apply_gated_search)
    end

    it "shows the collections" do
      get :show, id: collection
      expect(assigns[:presenter].title).to eq collection.title
      ids = assigns[:member_docs].map(&:id)
      expect(ids).to include(asset1.id, asset2.id, asset3.id)
    end
  end
end
