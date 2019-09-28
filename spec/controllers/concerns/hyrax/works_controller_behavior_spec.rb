# frozen_string_literal: true

RSpec.describe Hyrax::WorksControllerBehavior, type: :controller do
  subject(:controller) { controller_class.new }
  let(:paths)          { Rails.application.routes.url_helpers }
  routes               { Rails.application.routes }

  let(:controller_class) do
    module Hyrax::Test
      module ControllerBehavior
        class SimpleWorksController < ApplicationController
          include Hyrax::WorksControllerBehavior

          self.curation_concern_type = Hyrax::Test::SimpleWork
        end
      end
    end

    Hyrax::Test::ControllerBehavior::SimpleWorksController
  end

  before do
    @controller = controller

    routes.draw do
      match '/simple_works_test/:action/:id', controller: 'hyrax/test/controller_behavior/simple_works', via: [:get]
      devise_for :users
    end
  end

  after do
    Hyrax::Test.send(:remove_const, :ControllerBehavior)
    Rails.application.reload_routes!
  end

  shared_context 'with a logged in user' do
    let(:user) { create(:user) }

    before { sign_in user }
  end

  describe '#edit' do
    let(:work) { FactoryBot.valkyrie_create(:hyrax_work, :public) }
    let(:id)   { work.alternate_ids.first }

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

      it 'gives 401 for a user without edit access' do
        get :edit, params: { id: id }

        expect(response.status).to eq 401
      end
    end

    context 'when the user has edit access' do
      include_context 'with a logged in user'

      before do
        Hyrax::AccessControlList
          .new(resource: work)
          .grant(:edit)
          .to(user)
          .save
      end

      it 'renders the edit form' do
        get :edit, params: { id: id }

        expect(response).to render_template(:edit)
      end
    end
  end
end
