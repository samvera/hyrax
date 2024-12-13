# frozen_string_literal: true
RSpec.describe Hyrax::Admin::StatsController, type: :controller do
  let(:user) { create(:user) }

  context "a non admin" do
    describe "#show" do
      it 'is unauthorized' do
        get :show
        expect(response).to be_redirect
      end
    end
  end

  context "as an admin" do
    before do
      allow(controller).to receive(:authorize!).and_return(true)
    end

    describe "#show" do
      let(:expected_params) do
        ActionController::Parameters.new
      end

      it 'allows an authorized user to view the page' do
        get :show

        expect(response).to be_successful
        expect(assigns[:presenter]).to be_kind_of Hyrax::AdminStatsPresenter
        expect(assigns[:presenter])
          .to have_attributes(limit: 5, stats_filters: ActionController::Parameters.new({}))
      end

      context 'with a custom presenter' do
        let(:presenter_class) { Class.new(Hyrax::AdminStatsPresenter) }

        before { described_class.admin_stats_presenter = presenter_class }

        it 'allows an authorized user to view the page' do
          get :show

          expect(assigns[:presenter]).to be_kind_of presenter_class
          expect(assigns[:presenter])
            .to have_attributes(limit: 5, stats_filters: ActionController::Parameters.new({}))
        end
      end

      context 'with custom stats services' do
        let(:by_depositor_class) { Class.new(Hyrax::Statistics::Works::ByDepositor) }
        let(:service_config)     { { by_depositor: by_depositor_class } }

        before { described_class.admin_stats_services = service_config }

        it 'allows an authorized user to view the page' do
          get :show

          expect(assigns[:presenter])
            .to have_attributes(by_depositor: by_depositor_class)
        end
      end
    end
  end
end
