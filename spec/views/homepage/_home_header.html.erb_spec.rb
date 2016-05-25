
describe "sufia/homepage/_home_header.html.erb" do
  let(:groups) { [] }
  let(:ability) { instance_double("Ability") }
  let(:presenter) { Sufia::HomepagePresenter.new(ability) }

  describe "share your work button" do
    before do
      assign(:presenter, presenter)
      allow(controller).to receive(:current_ability).and_return(ability)
      allow(presenter).to receive(:display_share_button?).and_return(display_share_button)
      stub_template "sufia/homepage/_marketing.html.erb" => "marketing"
      render
    end
    context "when the button always displays" do
      let(:display_share_button) { true }
      it "displays" do
        expect(rendered).to have_content t("sufia.share_button")
      end
    end
    context "when the button displays for users with rights" do
      let(:display_share_button) { false }
      it "does not display" do
        expect(rendered).not_to have_content t("sufia.share_button")
      end
    end
  end
end
