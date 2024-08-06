# frozen_string_literal: true
require 'rails_helper'

RSpec.describe Hyrax::Admin::Analytics::WorkReportsController, type: :controller do
  routes { Hyrax::Engine.routes }
  describe 'GET #index' do
    context 'when user is not logged in' do
      it 'redirects to the login page' do
        get :index
        expect(response).to be_redirect
        expect(flash[:alert]).to eq("You need to sign in or sign up before continuing.")
      end
    end
  end
end
