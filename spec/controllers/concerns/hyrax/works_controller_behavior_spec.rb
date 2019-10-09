# frozen_string_literal: true

RSpec.describe Hyrax::WorksControllerBehavior, type: :controller do
  let(:paths) { Rails.application.routes.url_helpers }

  controller(ApplicationController) do
    include Hyrax::WorksControllerBehavior

    self.curation_concern_type = Hyrax::Test::BookResource
  end

  shared_context 'with a logged in user' do
    let(:user) { create(:user) }

    before { sign_in user }
  end

  describe '#edit' do
    let(:work) { FactoryBot.valkyrie_create(:hyrax_work, :public, alternate_ids: [id]) }
    let(:id)   { '123' }

    before { Hyrax.persister.save(resource: work) }

    it 'gives a 404 for a missing object' do
      expect { get :edit, params: { id: 'missing_id' } }
        .to raise_error Hyrax::ObjectNotFoundError
    end

    it 'redirects to new user login' do
      get :edit, params: { id: id }

      expect(response).to redirect_to paths.new_user_session_path(locale: :en)
    end

    context 'with a logged in user' do
      include_context 'with a logged in user'

      it 'gives unauthorized' do
        get :edit, params: { id: id }

        expect(response.status).to eq 401
      end
    end
  end
end
