require 'spec_helper'

RSpec.describe Hyrax::Dashboard::UserPresenter do
  let(:since) { nil }
  let(:context) { ActionView::TestCase::TestController.new.view_context }
  let(:user) { create(:user) }
  let(:instance) { described_class.new(user, context, since) }

  describe "#activity" do
    subject { instance.activity }
    let(:activity) { double }

    before do
      allow(user).to receive(:all_user_activity).and_return(activity)
    end

    it { is_expected.to eq activity }
  end

  describe "#notifications" do
    subject { instance.notifications }

    context "when the user has mail" do
      let(:user) { create(:user_with_mail) }
      it { is_expected.to be_truthy }
    end

    context "when the user doesn't have mail" do
      it { is_expected.to be_empty }
    end
  end

  describe "#transfers" do
    subject { instance.transfers }
    it { is_expected.to be_instance_of Hyrax::TransfersPresenter }
  end

  describe "#render_recent_activity" do
    subject(:rendered) { instance.render_recent_activity }
    context "when there is no activity" do
      before do
        allow(instance).to receive(:activity).and_return([])
      end

      it "returns a messages stating the user has no recent activity" do
        expect(rendered).to eq "User has no recent activity"
      end
    end
  end

  describe "#render_recent_notifications" do
    subject(:rendered) { instance.render_recent_notifications }
    context "when there are no notifications" do
      before do
        allow(instance).to receive(:notifications).and_return([])
      end
      it "returns a messages stating the user has no recent notifications" do
        expect(rendered).to eq "User has no notifications"
      end
    end
  end
end
