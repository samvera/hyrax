require 'spec_helper'

describe "homepage/_home_header.html.erb" do
  let(:groups) { [] }
  let(:ability) { instance_double("Ability") }
  describe "share your work button" do
    before do
      allow(controller).to receive(:current_ability).and_return(ability)
      allow(ability).to receive(:can?).with(:view_share_work, GenericFile).and_return(can_view_share_work)
      stub_template "homepage/_marketing.html.erb" => "marketing"
      render
    end
    context "when the user can view" do
      let(:can_view_share_work) { true }
      it "should display" do
        expect(rendered).to have_content t("sufia.share_button")
      end
    end
    context "when the user can't view" do
      let(:can_view_share_work) { false }
      it "should not display" do
        expect(rendered).not_to have_content t("sufia.share_button")
      end
    end
  end
end
