require 'spec_helper'

RSpec.describe Sufia::AdminController do
  describe '#show' do
    before do
      allow(controller).to receive(:authorize!).with(:read, :admin_dashboard).and_return(true)
    end
    it "is successful" do
      get :show
      expect(response).to be_success
    end
  end
end
