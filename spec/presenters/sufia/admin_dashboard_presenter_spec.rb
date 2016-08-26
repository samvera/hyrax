require 'spec_helper'

RSpec.describe Sufia::AdminDashboardPresenter do
  let(:instance) { described_class.new }

  describe "#user_count" do
    let!(:user1) { create(:user) }
    let!(:user2) { create(:user) }

    subject { instance.user_count }

    it { is_expected.to eq 2 }
  end
end
