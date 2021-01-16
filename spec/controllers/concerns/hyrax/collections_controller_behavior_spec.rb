# frozen_string_literal: true

RSpec.describe Hyrax::CollectionsControllerBehavior, :clean_repo, type: :controller do
  let(:paths) { controller.main_app }

  controller(ApplicationController) do
    include Hyrax::CollectionsControllerBehavior # rubocop:disable RSpec/DescribedClass
  end

  shared_context 'with a logged in user' do
    let(:user) { FactoryBot.create(:user) }

    before { sign_in user }
  end

  describe '#show' do
    context 'with a public collection' do
      let(:collection) { FactoryBot.valkyrie_create(:hyrax_collection, :public) }

      it 'shows the collection' do
        get :show, params: { id: collection.id }

        expect(response).to be_successful
      end

      context 'with a logged in user' do
        include_context 'with a logged in user'

        it 'shows the collection' do
          get :show, params: { id: collection.id }

          expect(response).to be_successful
        end
      end
    end
  end
end
