# frozen_string_literal: true
RSpec.describe Hyrax::BatchEditsHelper, type: :helper do
  describe "#render_check_all" do
    subject { helper.render_check_all }

    before do
      view.lookup_context.prefixes = ['hyrax/my']
      allow(helper).to receive(:params).and_return(controller: controller_path)
    end

    context "with my works" do
      let(:controller_path) { "hyrax/my/works" }

      it "shows the check all dropdown" do
        expect(subject).to have_content t("hyrax.dashboard.my.action.select_all")
        expect(subject).to have_content t("hyrax.dashboard.my.action.select_none")
      end
    end

    context "with my shares" do
      let(:controller_path) { "hyrax/my/shares" }

      it "shows the check all dropdown" do
        expect(subject).to have_content t("hyrax.dashboard.my.action.select_all")
        expect(subject).to have_content t("hyrax.dashboard.my.action.select_none")
      end
    end

    context "with my highlights" do
      let(:controller_path) { "hyrax/my/highlights" }

      it "shows the check all dropdown" do
        expect(subject).to have_content t("hyrax.dashboard.my.action.select_all")
        expect(subject).to have_content t("hyrax.dashboard.my.action.select_none")
      end
    end

    context "with my collections" do
      let(:controller_path) { "hyrax/my/collections" }

      it "show the check all dropdown" do
        expect(subject).to have_content t("hyrax.dashboard.my.action.select_all")
        expect(subject).to have_content t("hyrax.dashboard.my.action.select_none")
      end
    end

    context "with select all disabled" do
      let(:controller_path) { "foo" }

      it "does not show the check all dropdown" do
        assign(:disable_select_all, true)
        expect(subject).to have_css("input[disabled=disabled]")
      end
    end
  end
end
