
describe My::HighlightsController, type: :controller do
  describe "logged in user" do
    let(:user) { create(:user) }
    before { sign_in user }

    describe "#index" do
      before do
        GenericWork.destroy_all
        Collection.destroy_all
        @highlighted_work = create(:generic_work, user: user)
        user.trophies.create(work_id: @highlighted_work.id)

        @normal_work = create(:generic_work, user: user)
        other_user = create(:user)
        @unrelated_highlighted_work = create(:generic_work, user: other_user).tap do |r|
          r.edit_users += [user.user_key]
          r.save!
        end
        other_user.trophies.create(work_id: @unrelated_highlighted_work.id)
      end

      it "paginates" do
        work1 = create(:work, user: user)
        work2 = create(:work, user: user)
        user.trophies.create!(work_id: work1.id)
        user.trophies.create!(work_id: work2.id)
        get :index, per_page: 2
        expect(assigns[:document_list].length).to eq 2
        get :index, per_page: 2, page: 2
        expect(assigns[:document_list].length).to be >= 1
      end

      it "shows the correct files" do
        get :index
        expect(response).to be_successful
        # shows documents I've highlighted
        expect(assigns[:document_list].map(&:id)).to include(@highlighted_work.id)
        # doesn't show non-highlighted files
        expect(assigns[:document_list].map(&:id)).to_not include(@normal_work.id)
        # doesn't show other users' highlighted files
        expect(assigns[:document_list].map(&:id)).to_not include(@unrelated_highlighted_work.id)
      end
    end

    describe "when user has no highlights" do
      it "skips the call to Solr" do
        expect(controller).to_not receive(:search_results)
        get :index
      end
    end
  end
end
