require 'spec_helper'

RSpec.describe Hyrax::AdminDashboardPresenter do
  let(:instance) { described_class.new }

  describe "#user_count" do
    before do
      create(:user)
      create(:user)
      create(:user, :guest)
    end

    subject { instance.user_count }

    it { is_expected.to eq 2 }
  end
end
