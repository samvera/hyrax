
describe My::SharesController, type: :controller do
  describe "logged in user" do
    let(:user) { create(:user) }

    before do
      sign_in user
    end

    describe "#index" do
      let(:other_user)   { create(:user) }
      let(:someone_else) { create(:user) }

      let!(:my_file)                  { create(:file_set, user: user) }
      let!(:unshared_file)            { create(:file_set, user: other_user) }
      let!(:shared_with_me)           { create(:file_set, user: other_user, edit_users: [user, other_user]) }
      let!(:read_shared_with_me)      { create(:file_set, user: other_user, read_users: [user, other_user]) }
      let!(:shared_with_someone_else) { create(:file_set, user: other_user, edit_users: [someone_else, other_user]) }
      let!(:my_collection)            { create(:public_collection, user: user) }

      it "responds with success" do
        get :index
        expect(response).to be_successful
      end

      context "with multiple pages of results" do
        before { 2.times { create(:file_set, user: other_user, edit_users: [user, other_user]) } }
        it "paginates" do
          get :index, per_page: 2
          expect(assigns[:document_list].length).to eq 2
          get :index, per_page: 2, page: 2
          expect(assigns[:document_list].length).to be >= 1
        end
      end

      it "shows only documents that are shared with me via edit access" do
        get :index
        expect(assigns[:document_list].map(&:id)).to contain_exactly(shared_with_me.id)
      end
    end
  end
end
