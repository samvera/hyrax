require 'spec_helper'

describe Dashboard::SharesController do
  describe "logged in user" do
    before (:each) do
      @user = FactoryGirl.find_or_create(:archivist)
      sign_in @user
    end

    describe "#index" do
      before do
        GenericFile.destroy_all
        Collection.destroy_all
        @other_user = FactoryGirl.create(:user)
        @my_file = FactoryGirl.create(:generic_file, depositor: @user)
        @unshared_file = FactoryGirl.create(:generic_file, depositor: @other_user)
        @shared_with_me = FactoryGirl.create(:generic_file).tap do |r|
          r.apply_depositor_metadata @other_user
          r.edit_users += [@user.user_key]
          r.save!
        end
        @shared_with_someone_else = FactoryGirl.create(:generic_file).tap do |r|
          r.apply_depositor_metadata @user
          r.edit_users += [@other_user.user_key]
          r.save!
        end
      end

      it "should respond with success" do
        get :index
        expect(response).to be_successful
        expect(response).to render_template('dashboard/lists/index')
      end

      it "sets the controller name" do
        expect(controller.controller_name).to eq :dashboard
      end

      it "should paginate" do          
        FactoryGirl.create(:generic_file).tap do |r|
          r.apply_depositor_metadata @other_user
          r.edit_users += [@user.user_key]
          r.save!
        end
        FactoryGirl.create(:generic_file).tap do |r|
          r.apply_depositor_metadata @other_user
          r.edit_users += [@user.user_key]
          r.save!
        end
        get :index, per_page: 2
        expect(assigns[:document_list].length).to eq 2
        get :index, per_page: 2, page: 2
        expect(assigns[:document_list].length).to be >= 1
      end

      it "shows the correct documents" do
        get :index
        # shows documents shared with me
        expect(assigns[:document_list].map(&:id)).to include(@shared_with_me.id)
        # doesn't show normal files
        expect(assigns[:document_list].map(&:id)).to_not include(@my_file.id)
        expect(assigns[:document_list].map(&:id)).to_not include(@unshared_file.id)
        # doesn't show files shared with other users
        expect(assigns[:document_list].map(&:id)).to_not include(@shared_with_someone_else.id)
      end
    end
  end

  describe "not logged in as a user" do
    describe "#index" do
      it "should return an error" do
        get :index
        expect(response).to be_redirect
      end
    end
  end
end

