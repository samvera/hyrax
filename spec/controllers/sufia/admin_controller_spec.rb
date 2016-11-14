require 'spec_helper'

RSpec.describe Sufia::AdminController do
  describe '#show' do
    let(:service) { instance_double(Sufia::AdminSetService, search_results_with_work_count: results) }
    let(:results) { instance_double(Array) }

    before do
      allow(controller).to receive(:authorize!).with(:read, :admin_dashboard).and_return(true)
      allow(Sufia::AdminSetService).to receive(:new).and_return(service)
    end

    it "is successful" do
      get :show
      expect(response).to be_success
      expect(assigns[:admin_set_rows]).to eq results
    end
  end
end
