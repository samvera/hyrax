describe BatchEditsHelper, type: :helper do
  describe "#render_check_all" do
    before do
      view.lookup_context.prefixes = ['my']
    end

    context "with my works" do
      it "shows the check all dropdown" do
        allow(controller).to receive(:controller_name).and_return("my/works")
        expect(helper.render_check_all).to have_css("span.glyphicon-cog")
      end
    end

    context "with my shares" do
      it "shows the check all dropdown" do
        allow(controller).to receive(:controller_name).and_return("my/shares")
        expect(helper.render_check_all).to have_css("span.glyphicon-cog")
      end
    end

    context "with my highlights" do
      it "shows the check all dropdown" do
        allow(controller).to receive(:controller_name).and_return("my/shares")
        expect(helper.render_check_all).to have_css("span.glyphicon-cog")
      end
    end

    context "with my collections" do
      it "does not show the check all dropdown" do
        allow(controller).to receive(:controller_name).and_return("my/collections")
        expect(helper.render_check_all).to be_nil
      end
    end

    context "with select all disabled" do
      it "does not show the check all dropdown" do
        allow(helper).to receive(:params).and_return(controller: "foo")
        assign(:disable_select_all, true)
        expect(helper.render_check_all).to have_css("input[disabled=disabled]")
      end
    end
  end
end
