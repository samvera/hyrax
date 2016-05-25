describe ContentBlocksController, type: :controller do
  describe "#update" do
    let(:content_block) { FactoryGirl.create(:content_block) }
    before { request.env["HTTP_REFERER"] = "whence_i_came" }

    context "when not logged in" do
      it "UPDATE should redirect to sign_in path" do
        patch :update, id: content_block, content_block: { value: 'foo' }
        expect(response).to redirect_to main_app.new_user_session_path
      end

      it "CREATE should redirect to sign_in path" do
        post :create, content_block: { name: 'NNN', value: 'VVV' }
        expect(response).to redirect_to main_app.new_user_session_path
      end

      context "get INDEX" do
        let!(:current_researcher) { ContentBlock.create(name: ContentBlock::RESEARCHER, created_at: Time.zone.now) }
        let!(:old_researcher) { ContentBlock.create(name: ContentBlock::RESEARCHER, created_at: 2.hours.ago) }
        let!(:market_text) { ContentBlock.create(name: ContentBlock::MARKETING) }

        before { get :index }

        it "displays the list of featured researchers" do
          expect(response).to be_successful
          expect(response).to render_template(:index)
          expect(assigns(:content_blocks)).to eq [current_researcher, old_researcher]
        end
      end
    end

    context "when logged in" do
      let(:user) { FactoryGirl.create(:user) }
      before { allow(controller).to receive_messages(current_user: user) }

      context "as a user in the admin group" do
        before { expect(user).to receive(:groups).and_return(['admin', 'registered']) }

        it "UPDATE should save" do
          patch :update, id: content_block, content_block: { value: 'foo' }
          expect(response).to redirect_to "whence_i_came"
          expect(assigns[:content_block].value).to eq 'foo'
        end

        it "CREATE should save" do
          expect {
            post :create, content_block: { name: 'NNN', value: 'VVV', external_key: 'key' }
          }.to change { ContentBlock.count }.by(1)
          expect(response).to redirect_to "whence_i_came"
          expect(assigns[:content_block].name).to eq 'NNN'
          expect(assigns[:content_block].value).to eq 'VVV'
          expect(assigns[:content_block].external_key).to eq 'key'
        end
      end

      context "as a user without permission" do
        it "UPDATE is unauthorized" do
          patch :update, id: content_block, content_block: { value: 'foo' }
          expect(response.code).to eq '401'
          expect(response).to render_template(:unauthorized)
        end

        it "CREATE should redirect to root path" do
          post :create, content_block: { name: 'NNN', value: 'VVV' }
          expect(response.code).to eq '401'
          expect(response).to render_template(:unauthorized)
        end
      end
    end
  end
end
