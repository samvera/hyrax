# frozen_string_literal: true
require 'google/cloud/errors'

RSpec.describe Hyrax::AnalyticsErrorHandling, type: :controller do
  controller(ApplicationController) do
    include Hyrax::AnalyticsErrorHandling

    def index; end

    private

    def render_analytics_with_error
      head :service_unavailable
    end
  end

  before { allow(controller).to receive(:index).and_raise(error) }

  describe 'a Google error' do
    {
      Google::Cloud::PermissionDeniedError => 'permission',
      Google::Cloud::UnauthenticatedError => 'authentication',
      Google::Cloud::InvalidArgumentError => 'invalid_property',
      Google::Cloud::NotFoundError => 'invalid_property',
      Google::Cloud::ResourceExhaustedError => 'quota_exceeded',
      Google::Cloud::InternalError => 'general'
    }.each do |error_class, type|
      context "when it is #{error_class}" do
        let(:error) { error_class.new('boom') }

        it "reports the #{type} error with its title and steps" do
          get :index

          expect(response).to have_http_status(:service_unavailable)
          expect(assigns(:analytics_error)).to include(type: type,
                                                       title: I18n.t("hyrax.admin.analytics.errors.#{type}.title"),
                                                       details: 'boom')
        end
      end
    end

    context 'when the class says one thing and the message another' do
      let(:error) { Google::Cloud::PermissionDeniedError.new('invalid credentials') }

      it 'uses the class' do
        get :index

        expect(assigns(:analytics_error)).to include(type: 'permission')
      end
    end

    context 'when the class is not specific and the message names a quota' do
      let(:error) { Google::Cloud::InternalError.new('quota exceeded') }

      it 'falls back to the message' do
        get :index

        expect(assigns(:analytics_error)).to include(type: 'quota_exceeded')
      end
    end
  end

  context 'with an error unrelated to analytics' do
    let(:error) { RuntimeError.new('unrelated failure').tap { |e| e.set_backtrace(['/app/models/thing.rb:1']) } }

    it 're-raises it' do
      expect { get :index }.to raise_error(RuntimeError, 'unrelated failure')
    end
  end
end
