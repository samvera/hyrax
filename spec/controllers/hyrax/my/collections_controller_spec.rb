# frozen_string_literal: true
RSpec.describe Hyrax::My::CollectionsController, :clean_repo, type: :controller do
  context "with a logged in user" do
    let(:user) { FactoryBot.create(:user) }

    before { sign_in(user) }

    describe "#index" do
      it "sets breadcrumbs" do
        expect(controller).to receive(:add_breadcrumb).with('Home', root_path(locale: 'en'))
        expect(controller).to receive(:add_breadcrumb).with('Dashboard', dashboard_path(locale: 'en'))
        expect(controller).to receive(:add_breadcrumb).with('Collections', my_collections_path(locale: 'en'))
        get :index, params: { per_page: 1 }
      end

      it "shows empty results with no collections" do
        get :index, params: { per_page: 1 }

        expect(assigns[:document_list]).to be_empty
      end

      context "with collections deposited by user" do
        let!(:user_collections) do
          [FactoryBot.valkyrie_create(:hyrax_collection, user: user),
           FactoryBot.valkyrie_create(:hyrax_collection, user: user)]
        end

        let!(:other_collections) do
          [FactoryBot.valkyrie_create(:hyrax_collection),
           FactoryBot.valkyrie_create(:hyrax_collection)]
        end

        it "shows only user collections" do
          get :index, params: { per_page: 10 }

          expect(assigns[:document_list])
            .to contain_exactly(have_attributes(id: user_collections.first.id),
                                have_attributes(id: user_collections.last.id))
        end
      end
    end
  end

  describe "#search_facet_path" do
    it do
      expect(controller.send(:search_facet_path, id: 'keyword_sim'))
        .to eq "/dashboard/my/collections/facet/keyword_sim?locale=en"
    end
  end

  describe "#search_builder_class" do
    it 'has a default search builder class' do
      expect(controller.blacklight_config.search_builder_class)
        .to eq Hyrax::My::CollectionsSearchBuilder
    end
  end
end
