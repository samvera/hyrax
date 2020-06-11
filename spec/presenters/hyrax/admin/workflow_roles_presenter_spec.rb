# frozen_string_literal: true
RSpec.describe Hyrax::Admin::WorkflowRolesPresenter do
  let(:presenter) { described_class.new }

  describe "#users" do
    subject { presenter.users }

    let!(:user) { create(:user) }

    before do
      create(:user, :guest)
    end
    it "doesn't include guests" do
      expect(subject).to eq [user]
    end
  end
end
