describe BatchEditsHelper, type: :helper do
  describe "#render_check_all" do
    subject { helper.render_check_all }
    before do
      view.lookup_context.prefixes = ['my']
    end

    context "with my works" do
      it "shows the check all dropdown" do
        allow(controller).to receive(:params).and_return(controller: "my/works")
        expect(subject).to have_css("span.caret")
        expect(subject).to have_content t("sufia.dashboard.my.action.select_all")
        expect(subject).to have_content t("sufia.dashboard.my.action.select_none")
      end
    end

    context "with my shares" do
      it "shows the check all dropdown" do
        allow(controller).to receive(:params).and_return(controller: "my/shares")
        expect(subject).to have_css("span.caret")
        expect(subject).to have_content t("sufia.dashboard.my.action.select_all")
        expect(subject).to have_content t("sufia.dashboard.my.action.select_none")
      end
    end

    context "with my highlights" do
      it "shows the check all dropdown" do
        allow(controller).to receive(:params).and_return(controller: "my/shares")
        expect(subject).to have_css("span.caret")
        expect(subject).to have_content t("sufia.dashboard.my.action.select_all")
        expect(subject).to have_content t("sufia.dashboard.my.action.select_none")
      end
    end

    context "with my collections" do
      it "does not show the check all dropdown" do
        allow(controller).to receive(:params).and_return(controller: "my/collections")
        expect(subject).to be_nil
      end
    end

    context "with select all disabled" do
      it "does not show the check all dropdown" do
        allow(helper).to receive(:params).and_return(controller: "foo")
        assign(:disable_select_all, true)
        expect(subject).to have_css("input[disabled=disabled]")
      end
    end
  end
end
