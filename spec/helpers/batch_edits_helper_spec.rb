require 'spec_helper'

describe BatchEditsHelper, type: :helper do
  describe "#render_check_all" do
    before do
      @document_list = ["doc1", "doc2"]
      @upload_set_size_on_other_page = 1
      @max_upload_set_size = 10
    end

    context "with my files" do
      it "shows the check all dropdown" do
        allow(helper).to receive(:params).and_return(controller: "my/files")
        allow(helper).to receive(:controller_name).and_return("batch_edits")
        expect(helper.render_check_all).to have_css("span.glyphicon-cog")
      end

      it "shows my action menu for my controller" do
        allow(helper).to receive(:params).and_return(controller: "my")
        allow(helper).to receive(:controller_name).and_return("my")
        expect(helper.render_check_all).not_to have_content("ABC")
      end
    end

    context "with my collections" do
      it "does not show the check all dropdown" do
        allow(helper).to receive(:params).and_return(controller: "my/collections")
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
