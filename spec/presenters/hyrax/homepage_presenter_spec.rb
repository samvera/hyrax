# frozen_string_literal: true
RSpec.describe Hyrax::HomepagePresenter do
  let(:presenter) { described_class.new(ability, collections) }
  let(:ability) { Ability.new(user) }
  let(:collections) { double }
  let(:user) { build(:user) }

  describe "#collections" do
    subject { presenter.collections }

    it { is_expected.to eq collections }
  end

  describe "#display_share_button?" do
    subject { presenter.display_share_button? }

    context "when config is set to display_share_button_when_not_logged_in" do
      context "and the user is registered" do
        before do
          allow(user).to receive(:new_record?).and_return(false)
          allow(Hyrax.config).to receive(:display_share_button_when_not_logged_in?).and_return(true)
          allow(ability).to receive(:can_create_any_work?).and_return(false)
        end
        it { is_expected.to be false }
      end

      context "and the user is a guest" do
        before do
          allow(Hyrax.config).to receive(:display_share_button_when_not_logged_in?).and_return(true)
        end
        it { is_expected.to be true }
      end
    end

    context "when config is not set to display_share_button_when_not_logged_in" do
      before do
        allow(Hyrax.config).to receive(:display_share_button_when_not_logged_in?).and_return(false)
        allow(ability).to receive(:can_create_any_work?).and_return(false)
      end
      it { is_expected.to be false }
    end
  end
end
