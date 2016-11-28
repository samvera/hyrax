require "spec_helper"

class SelectsCollectionsController < ApplicationController
  include Blacklight::Catalog
  include Hydra::Controller::ControllerBehavior
  Deprecation.silence CurationConcerns::SelectsCollections do
    include CurationConcerns::SelectsCollections
  end
end

describe SelectsCollectionsController, type: :controller do
  describe "#find_collections" do
    it "uses the search builder" do
      expect(subject.collections_search_builder_class.default_processor_chain)
        .to include(:default_solr_parameters, :add_query_to_solr, :add_access_controls_to_solr_params)
      expect(CurationConcerns::CollectionSearchBuilder).to receive(:new).with(subject).and_call_original
      subject.find_collections
    end
  end

  describe "Select Collections" do
    let(:user) { FactoryGirl.create(:user) }
    let!(:collection) { FactoryGirl.create(:collection, read_groups: ['public'], user: user) }
    let!(:collection2) { FactoryGirl.create(:collection, read_users: [user.user_key]) }
    let!(:collection3) { FactoryGirl.create(:collection, edit_users: [user.user_key]) }
    let!(:collection4) { FactoryGirl.create(:collection) }

    describe "Public Access" do
      it "only returns public collections" do
        subject.find_collections
        expect(assigns[:user_collections].map(&:id)).to match_array [collection.id]
      end

      context "when there are more than 10" do
        before do
          11.times do
            FactoryGirl.create(:collection, read_groups: ["public"], user: user)
          end
        end

        it "returns all public collections" do
          subject.find_collections
          expect(assigns[:user_collections].count).to eq(12)
        end
      end
    end

    describe "Read Access" do
      describe "not signed in" do
        it "redirects the user to sign in" do
          expect(subject).to receive(:authenticate_user!)
          subject.find_collections_with_read_access
        end
      end
      describe "signed in" do
        before { sign_in user }

        it "only returns public and read access (edit access implies read) collections" do
          subject.find_collections_with_read_access
          expect(assigns[:user_collections].map(&:id)).to match_array [collection.id, collection2.id, collection3.id]
        end
      end
    end

    describe "Edit Access" do
      describe "not signed in" do
        it "redirects the user to sign in" do
          expect(subject).to receive(:authenticate_user!)
          subject.find_collections_with_edit_access
        end
      end

      describe "signed in" do
        before { sign_in user }

        it "only returns public or editable collections" do
          subject.find_collections_with_edit_access
          expect(assigns[:user_collections].map(&:id)).to match_array [collection.id, collection3.id]
        end

        it "only returns public or editable collections & instructions" do
          subject.find_collections_with_edit_access(true)
          expect(assigns[:user_collections].map(&:id)).to match_array [-1, collection.id, collection3.id]
        end

        context "after querying for read access" do
          before do
            subject.find_collections
            subject.find_collections_with_edit_access
          end

          it "returns collections with edit access" do
            expect(assigns[:user_collections].map(&:id)).to match_array [collection.id, collection3.id]
          end
        end
      end
    end
  end
end
