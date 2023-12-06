# frozen_string_literal: true
RSpec.describe Hyrax::My::HighlightsController, :clean_repo, type: :controller do
  describe "logged in user" do
    let(:user) { create(:user) }

    before { sign_in user }

    describe "#index" do
      before do
        user.trophies.create(work_id: highlighted_work.id)
        other_user.trophies.create(work_id: unrelated_highlighted_work.id)
      end

      let(:other_user) { create(:user) }
      let(:highlighted_work) { valkyrie_create(:monograph, edit_users: [user]) }
      let!(:normal_work) { valkyrie_create(:monograph, edit_users: [user]) }
      let(:unrelated_highlighted_work) { valkyrie_create(:monograph, edit_users: [user, other_user]) }

      it "paginates" do
        work1 = valkyrie_create(:monograph, edit_users: [user])
        work2 = valkyrie_create(:monograph, edit_users: [user])
        user.trophies.create!(work_id: work1.id)
        user.trophies.create!(work_id: work2.id)
        get :index, params: { per_page: 2 }
        expect(assigns[:document_list].length).to eq 2
        get :index, params: { per_page: 2, page: 2 }
        expect(assigns[:document_list].length).to be >= 1
      end

      it "shows the correct files" do
        get :index
        expect(response).to be_successful
        # shows documents I've highlighted
        expect(assigns[:document_list].map(&:id)).to include(highlighted_work.id)
        # doesn't show non-highlighted files
        expect(assigns[:document_list].map(&:id)).not_to include(normal_work.id)
        # doesn't show other users' highlighted files
        expect(assigns[:document_list].map(&:id)).not_to include(unrelated_highlighted_work.id)
      end
    end

    describe "when user has no highlights" do
      it "skips the call to Solr" do
        expect(controller).not_to receive(:search_results)
        get :index
      end
    end
  end
end
