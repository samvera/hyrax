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

  describe "#repository_objects" do
    subject { instance.repository_objects }
    it { is_expected.to be_kind_of Hyrax::Admin::RepositoryObjectPresenter }
  end
end
