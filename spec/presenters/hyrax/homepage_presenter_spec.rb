describe Hyrax::HomepagePresenter do
  let(:presenter) { described_class.new(ability) }
  let(:ability) { instance_double("Ability") }
  subject { presenter }

  describe "#display_share_button?" do
    subject { presenter.display_share_button? }
    context "when config is set to always_display_share_button" do
      before do
        allow(Hyrax.config).to receive(:always_display_share_button?).and_return(true)
      end
      it { is_expected.to be true }
    end
    context "when config is not set to always_display_share_button" do
      before do
        allow(Hyrax.config).to receive(:always_display_share_button?).and_return(false)
        allow(ability).to receive(:can_create_any_work?).and_return(false)
      end
      it { is_expected.to be false }
    end
  end
end
