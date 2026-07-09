# frozen_string_literal: true
require 'rails_helper'

RSpec.describe Hyrax::Admin::Analytics::WorkReportsController, type: :controller do
  routes { Hyrax::Engine.routes }

  around do |example|
    current_reporting = Hyrax.config.analytics_reporting
    Hyrax.config.analytics_reporting = true
    example.run
    Hyrax.config.analytics_reporting = current_reporting
  end

  describe 'GET #index' do
    context 'when user is not logged in' do
      it 'redirects to the login page' do
        get :index
        expect(response).to be_redirect
        expect(flash[:alert]).to eq("You need to sign in or sign up before continuing.")
      end
    end

    context 'when multiple file set model types are registered' do
      let(:admin_user) { FactoryBot.create(:admin) }

      before do
        sign_in admin_user
        allow(Hyrax::ModelRegistry).to receive(:file_set_rdf_representations)
          .and_return(['FileSet', 'Hyrax::FileSet'])
        allow(Hyrax::ModelRegistry).to receive(:work_rdf_representations)
          .and_return(['GenericWork'])
        allow(Hyrax::SolrService).to receive(:query).and_return([])
        allow(Hyrax::Analytics).to receive(:top_events).and_return([])
        allow(Hyrax::Analytics).to receive(:daily_events).and_return(double(results: []))
      end

      it 'constructs a valid solr query with parenthesized OR syntax for multiple file set models' do
        expect(Hyrax::SolrService).to receive(:query)
          .with('has_model_ssim:("FileSet" OR "Hyrax::FileSet")',
                hash_including(fl: 'title_tesim, id', rows: 50_000))
          .and_return([])

        get :index
        expect(response).to be_successful
      end
    end
  end
end
