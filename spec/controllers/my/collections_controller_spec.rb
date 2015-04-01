require 'spec_helper'

describe My::CollectionsController, :type => :controller do
  describe "logged in user" do
    before (:each) do
      @user = FactoryGirl.find_or_create(:archivist)
      sign_in @user
    end

    describe "#index" do
      before do
        GenericFile.destroy_all
        Collection.destroy_all
        @my_file = FactoryGirl.create(:generic_file, depositor: @user)
        @my_collection = Collection.new(title: "test collection").tap do |c|
          c.apply_depositor_metadata(@user.user_key)
          c.save!
        end
        @unrelated_collection = Collection.create(title: "test collection") do |c|
          c.apply_depositor_metadata(FactoryGirl.create(:user).user_key)
        end
      end

      it "should respond with success" do
        get :index
        expect(response).to be_successful
      end

      it "should paginate" do          
        other_user = FactoryGirl.create(:user)
        Collection.new(title: "test collection").tap do |c|
          c.apply_depositor_metadata(@user.user_key)
          c.save!
        end
        Collection.new(title: "test collection").tap do |c|
          c.apply_depositor_metadata(@user.user_key)
          c.save!
        end
        get :index, per_page: 2
        expect(assigns[:document_list].length).to eq 2
        get :index, per_page: 2, page: 2
        expect(assigns[:document_list].length).to be >= 1
      end

      it "shows the correct collections" do
        get :index
        # shows my collections
        expect(assigns[:document_list].map(&:id)).to include(@my_collection.id)
        # doesn't show files
        expect(assigns[:document_list].map(&:id)).to_not include(@my_file.id)
        # doesn't show other users' collections" do
        expect(assigns[:document_list].map(&:id)).to_not include(@unrelated_collection.id)
      end
    end
  end

end
