RSpec.describe Hyrax::Admin::CollectionTypeParticipantsController, type: :controller do
  context 'anonymous user' do
    let(:collection_type) { create(:collection_type) }
    let(:valid_attributes) do
      {
        hyrax_collection_type_id: collection_type.id,
        access: 'creator',
        agent_id: 'example@example.com',
        agent_type: 'user'
      }
    end

    describe '#create' do
      it 'does not create a pariticpant' do
        post :create
        expect do
          post :create, params: { collection_type_participant: valid_attributes }
        end.to change(Hyrax::CollectionTypeParticipant, :count).by(0)
      end

      it "returns http redirect" do
        post :create
        expect(response).to have_http_status(:redirect)
      end
    end

    describe '#destroy' do
      let!(:collection_type_participant) { create(:collection_type_participant) }

      it 'does not destroy a participant' do
        expect do
          delete :destroy, params: { id: collection_type_participant.to_param }
        end.to change(Hyrax::CollectionTypeParticipant, :count).by(0)
      end

      it "returns http redirect" do
        delete :destroy, params: { id: collection_type_participant.to_param }
        expect(response).to have_http_status(:redirect)
      end
    end
  end

  context "unauthorized user" do
    let(:user) { create(:user) }
    let(:collection_type) { create(:collection_type) }
    let(:valid_attributes) do
      {
        hyrax_collection_type_id: collection_type.id,
        access: 'creator',
        agent_id: 'example@example.com',
        agent_type: 'user'
      }
    end

    before do
      allow(controller.current_ability).to receive(:can?).with(any_args).and_return(false)
      sign_in user
    end

    describe "#create" do
      it 'does not create a pariticpant' do
        post :create
        expect do
          post :create, params: { collection_type_participant: valid_attributes }
        end.to change(Hyrax::CollectionTypeParticipant, :count).by(0)
      end

      it "returns http redirect" do
        post :create
        expect(response).to have_http_status(:redirect)
      end
    end

    describe "#destroy" do
      let!(:collection_type_participant) { create(:collection_type_participant) }

      it 'does not destroy a participants' do
        expect do
          delete :destroy, params: { id: collection_type_participant.to_param }
        end.to change(Hyrax::CollectionTypeParticipant, :count).by(0)
      end
      it "returns http redirect" do
        delete :destroy, params: { id: :id }
        expect(response).to have_http_status(:redirect)
      end
    end
  end

  context "authorized user" do
    let(:collection_type) { create(:collection_type) }
    let(:valid_attributes) do
      {
        hyrax_collection_type_id: collection_type.id,
        access: Hyrax::CollectionTypeParticipant::CREATE_ACCESS,
        agent_id: 'example@example.com',
        agent_type: 'user'
      }
    end

    let(:valid_session) { {} }
    let(:collection_type_participant) { create(:collection_type_participant) }
    let(:user) { create(:user) }

    before do
      allow(controller.current_ability).to receive(:can?).with(any_args).and_return(true)
      sign_in user
    end

    describe "#create" do
      context "with valid params" do
        it "creates a new CollectionTypeParticipant" do
          expect do
            post :create, params: { collection_type_participant: valid_attributes }, session: valid_session
          end.to change(Hyrax::CollectionTypeParticipant, :count).by(1)
        end

        it "redirects to the edit_admin_collection_type with participants panel active" do
          post :create, params: { collection_type_participant: valid_attributes }, session: valid_session
          expect(response).to redirect_to(edit_admin_collection_type_path(collection_type.id, anchor: 'participants'))
        end

        it "assigns all attributes" do
          post :create, params: { collection_type_participant: valid_attributes }, session: valid_session
          expect(assigns[:collection_type_participant].attributes.symbolize_keys).to include(valid_attributes)
        end
      end

      context "with invalid params" do
        it "does not create a new CollectionTypeParticipant" do
          post :create, params: { collection_type_participant: { hyrax_collection_type_id: '1' } }, session: valid_session
          expect do
            post :create, params: { collection_type_participant: { hyrax_collection_type_id: '1' } }, session: valid_session
          end.to change(Hyrax::CollectionTypeParticipant, :count).by(0)
        end
      end
    end

    describe "#destroy" do
      it "destroys the requested collection_type_participant" do
        expect(collection_type_participant).to be_persisted
        expect do
          delete :destroy, params: { id: collection_type_participant.to_param }, session: valid_session
        end.to change(Hyrax::CollectionTypeParticipant, :count).by(-1)
      end

      it "redirects to edit the collections participants list" do
        delete :destroy, params: { id: collection_type_participant.to_param }, session: valid_session
        expect(response).to redirect_to(edit_admin_collection_type_path(collection_type_participant.hyrax_collection_type_id, anchor: 'participants'))
      end
    end
  end
end
