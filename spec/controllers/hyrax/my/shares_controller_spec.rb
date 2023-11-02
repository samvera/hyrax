# frozen_string_literal: true
RSpec.describe Hyrax::My::SharesController, :clean_repo, type: :controller do
  describe "logged in user" do
    let(:user) { create(:user) }

    before { sign_in user }

    describe "#index" do
      let(:other_user)   { create(:user) }
      let(:someone_else) { create(:user) }

      let!(:shared_with_me) do
        valkyrie_create(:monograph, depositor: other_user.user_key, edit_users: [user, other_user])
      end

      it "responds with success" do
        get :index
        expect(response).to be_successful
      end

      context "with multiple pages of results" do
        before { 2.times { valkyrie_create(:monograph, depositor: other_user.user_key, edit_users: [user, other_user]) } }

        it "paginates" do
          get :index, params: { per_page: 2 }
          expect(assigns[:document_list].length).to eq 2

          get :index, params: { per_page: 2, page: 2 }
          expect(assigns[:document_list].length).to eq 1
        end
      end

      context "with other extant documents" do
        let!(:my_work) { valkyrie_create(:monograph, depositor: user.user_key) }
        let!(:unshared_work) { valkyrie_create(:monograph, depositor: other_user.user_key) }
        let!(:read_shared_with_me) do
          valkyrie_create(:monograph, depositor: other_user.user_key, read_users: [user, other_user])
        end
        let!(:shared_with_someone_else) do
          valkyrie_create(:monograph, depositor: other_user.user_key, edit_users: [someone_else, other_user])
        end
        let!(:my_collection) { valkyrie_create(:hyrax_collection, :public, user: user) }

        it "shows only documents that are shared with me via edit access" do
          get :index
          expect(assigns[:document_list].map(&:id)).to contain_exactly(shared_with_me.id)
        end
      end
    end
  end

  describe "#search_facet_path" do
    subject { controller.send(:search_facet_path, id: 'keyword_sim') }

    it { is_expected.to eq "/dashboard/shares/facet/keyword_sim?locale=en" }
  end
end
