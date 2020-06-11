# frozen_string_literal: true
RSpec.describe Hyrax::Admin::DashboardPresenter do
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

  describe "#repository_objects" do
    subject { instance.repository_objects }

    it { is_expected.to be_kind_of Hyrax::Admin::RepositoryObjectPresenter }
  end

  describe "#repository_growth" do
    subject { instance.repository_growth }

    it { is_expected.to be_kind_of Hyrax::Admin::RepositoryGrowthPresenter }
  end

  describe "#user_activity" do
    subject { instance.user_activity }

    it { is_expected.to be_kind_of Hyrax::Admin::UserActivityPresenter }
  end
end
