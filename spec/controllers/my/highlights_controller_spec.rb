require 'spec_helper'

describe My::HighlightsController, type: :controller do
  describe "logged in user" do
    before do
      @user = FactoryGirl.find_or_create(:archivist)
      sign_in @user
    end

    describe "#index" do
      before do
        GenericWork.destroy_all
        Collection.destroy_all
        @highlighted_work = FactoryGirl.create(:generic_work).tap do |r|
          r.apply_depositor_metadata @user
          r.save!
        end
        @user.trophies.create(generic_work_id: @highlighted_work.id)
        @normal_work = FactoryGirl.create(:generic_work).tap do |r|
          r.apply_depositor_metadata @user
          r.save!
        end
        other_user = FactoryGirl.create(:user)
        @unrelated_highlighted_work = FactoryGirl.create(:generic_work).tap do |r|
          r.apply_depositor_metadata other_user
          r.edit_users += [@user.user_key]
          r.save!
        end
        other_user.trophies.create(generic_work_id: @unrelated_highlighted_work.id)
      end

      it "responds with success" do
        get :index
        expect(response).to be_successful
      end

      it "paginates" do
        @work1 = GenericWork.create { |w| w.apply_depositor_metadata(@user) }
        @user.trophies.create(generic_work_id: @work1.id)
        @work2 = GenericWork.create { |w| w.apply_depositor_metadata(@user) }
        @user.trophies.create(generic_work_id: @work2.id)
        get :index, per_page: 2
        expect(assigns[:document_list].length).to eq 2
        get :index, per_page: 2, page: 2
        expect(assigns[:document_list].length).to be >= 1
      end

      it "shows the correct files" do
        get :index
        # shows documents I've highlighted
        expect(assigns[:document_list].map(&:id)).to include(@highlighted_work.id)
        # doesn't show non-highlighted files
        expect(assigns[:document_list].map(&:id)).to_not include(@normal_work.id)
        # doesn't show other users' highlighted files
        expect(assigns[:document_list].map(&:id)).to_not include(@unrelated_highlighted_work.id)
      end
    end
  end
end
