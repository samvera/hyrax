require 'spec_helper'

describe My::HighlightsController, :type => :controller do
  describe "logged in user" do
    before (:each) do
      @user = FactoryGirl.find_or_create(:archivist)
      sign_in @user
    end

    describe "#index" do
      before do
        GenericFile.destroy_all
        Collection.destroy_all
        @highlighted_file = FactoryGirl.create(:generic_file, depositor: @user)
        @user.trophies.create(generic_file_id: @highlighted_file.id)
        @normal_file = FactoryGirl.create(:generic_file, depositor: @user)
        other_user = FactoryGirl.create(:user)
        @unrelated_highlighted_file = FactoryGirl.create(:generic_file).tap do |r|
          r.apply_depositor_metadata other_user
          r.edit_users += [@user.user_key]
          r.save!
        end
        other_user.trophies.create(generic_file_id: @unrelated_highlighted_file.id)
      end

      it "should respond with success" do
        get :index
        expect(response).to be_successful
      end

      it "should paginate" do          
        @user.trophies.create(generic_file_id: FactoryGirl.create(:generic_file, depositor: @user).id)
        @user.trophies.create(generic_file_id: FactoryGirl.create(:generic_file, depositor: @user).id)
        get :index, per_page: 2
        expect(assigns[:document_list].length).to eq 2
        get :index, per_page: 2, page: 2
        expect(assigns[:document_list].length).to be >= 1
      end

      it "shows the correct files" do
        get :index
        # shows documents I've highlighted
        expect(assigns[:document_list].map(&:id)).to include(@highlighted_file.id)
        # doesn't show non-highlighted files
        expect(assigns[:document_list].map(&:id)).to_not include(@normal_file.id)
        # doesn't show other users' highlighted files
        expect(assigns[:document_list].map(&:id)).to_not include(@unrelated_highlighted_file.id)
      end
    end
  end

end
