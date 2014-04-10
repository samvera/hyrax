require 'spec_helper'

describe ContentBlocksController do
  describe "#update" do
    let(:content_block) { FactoryGirl.create(:content_block) }
    before { request.env["HTTP_REFERER"] = "whence_i_came" }

    context "when not logged in" do
      it "should redirect to root path" do
        patch :update, id: content_block, content_block: { value: 'foo' }
        expect(response).to redirect_to main_app.new_user_session_path
      end
    end

    context "when logged in" do
      let(:user) { FactoryGirl.create(:user) }
      before { controller.stub(current_user: user) }

      context "as a user in the admin group" do
        before { user.should_receive(:groups).and_return( ['admin', 'registered']) }

        it "should save" do
          patch :update, id: content_block, content_block: { value: 'foo' }
          expect(response).to redirect_to "whence_i_came"
          expect(assigns[:content_block].value).to eq 'foo'
        end
      end

      context "as a user without permission" do
        it "should redirect to root path" do
          patch :update, id: content_block, content_block: { value: 'foo' }
          expect(response).to redirect_to root_path
        end
      end
    end
  end
end
