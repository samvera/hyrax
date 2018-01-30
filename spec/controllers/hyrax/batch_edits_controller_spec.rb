RSpec.describe Hyrax::BatchEditsController, type: :controller do
  let(:user) { create(:user) }

  before do
    sign_in user
    allow_any_instance_of(User).to receive(:groups).and_return([])
    request.env["HTTP_REFERER"] = 'test.host/original_page'
  end

  describe "#edit" do
    let(:one) { create(:work, creator: ["Fred"], title: ["abc"], language: ['en']) }
    let(:two) { create(:work, creator: ["Wilma"], title: ["abc2"], publisher: ['Rand McNally'], language: ['en'], resource_type: ['bar']) }
    let(:three) { create(:work, creator: ["Dino"], title: ["abc3"]) }

    before do
      controller.batch = [one.id, two.id, three.id]
      expect(controller).to receive(:can?).with(:edit, one.id).and_return(true)
      expect(controller).to receive(:can?).with(:edit, two.id).and_return(true)
      expect(controller).to receive(:can?).with(:edit, three.id).and_return(false)
    end

    it "is successful" do
      expect(controller).to receive(:add_breadcrumb).with(I18n.t('hyrax.dashboard.title'), Hyrax::Engine.routes.url_helpers.dashboard_path(locale: 'en'))
      expect(controller).to receive(:add_breadcrumb).with(I18n.t('hyrax.dashboard.my.works'), Hyrax::Engine.routes.url_helpers.my_works_path(locale: 'en'))
      get :edit
      expect(response).to be_successful
      expect(assigns[:form].model.creator).to match_array ["Fred", "Wilma"]
    end
  end

  describe "update" do
    let(:user) { build(:user) }
    let!(:one) do
      create(:work, creator: ["Fred"], title: ["abc"], language: ['en'], user: user)
    end

    let!(:two) do
      create(:work, creator: ["Fred"], title: ["abc"], language: ['en'], user: user)
    end

    let!(:three) do
      create(:work, creator: ["Fred"], title: ["abc"], language: ['en'])
    end

    let(:mycontroller) { "hyrax/my/works" }

    before do
      # TODO: why aren't we just submitting batch_document_ids[] as a parameter?
      controller.batch = [one.id, two.id, three.id]
      expect(controller).to receive(:can?).with(:edit, one.id).and_return(true)
      expect(controller).to receive(:can?).with(:edit, two.id).and_return(true)
      expect(controller).to receive(:can?).with(:edit, three.id).and_return(false)
    end

    it "is successful" do
      put :update, params: { update_type: "delete_all" }
      expect(response).to redirect_to(dashboard_path(locale: 'en'))
      expect { GenericWork.find(one.id) }.to raise_error(Ldp::Gone)
      expect { GenericWork.find(two.id) }.to raise_error(Ldp::Gone)
      expect(GenericWork).to exist(three.id)
    end

    it "redirects to the return controller" do
      put :update, params: { update_type: "delete_all", return_controller: mycontroller }
      expect(response).to redirect_to(Hyrax::Engine.routes.url_for(controller: mycontroller, only_path: true, locale: 'en'))
    end

    it "updates the records" do
      put :update, params: { update_type: "update", generic_work: { subject: ["zzz"] } }
      expect(response).to be_redirect
      expect(GenericWork.find(one.id).subject).to eq ["zzz"]
      expect(GenericWork.find(two.id).subject).to eq ["zzz"]
      expect(GenericWork.find(three.id).subject).to be_empty
    end

    it "updates permissions" do
      put :update, params: { update_type: "update", visibility: "authenticated" }
      expect(response).to be_redirect
      expect(GenericWork.find(one.id).visibility).to eq "authenticated"
      expect(GenericWork.find(two.id).visibility).to eq "authenticated"
      expect(GenericWork.find(three.id).visibility).to eq "restricted"
    end
  end

  describe "#destroy_collection" do
    let(:user) { create(:user) }

    let!(:empty_adminset) { create(:admin_set, title: ['Empty Admin Set'], edit_users: [user], creator: [user.user_key], with_permission_template: true) }
    let!(:adminset) { create(:admin_set, title: ['Admin Set with Work'], edit_users: [user], creator: [user.user_key], with_permission_template: true) }
    let!(:work) { create(:work, title: ["King Louie"], admin_set: adminset, user: user) }

    let(:collection1) do
      create(:public_collection, title: ["My First Collection"],
                                 description: ["My incredibly detailed description of the collection"],
                                 user: user)
    end

    let(:collection2) do
      create(:public_collection, title: ["My Other Collection"],
                                 description: ["My incredibly detailed description of the other collection"],
                                 user: user)
    end

    let!(:work1) { create(:work, title: ["First of the Assets"], member_of_collections: [collection1], user: user) }
    let(:work2)  { create(:work, title: ["Second of the Assets"], user: user) }

    let(:mycontroller) { "hyrax/my/works" }
    let(:curation_concern) { create(:work1, user: user) }

    context 'when user has edit access' do
      it "deletes collections with and without works in it and an empty admin set." do
        controller.batch = [collection1.id, collection2.id, empty_adminset.id]
        delete :destroy_collection, params: { update_type: "delete_all" }
        expect { Collection.find(collection1.id) }.to raise_error(Ldp::Gone)
        expect { Collection.find(collection2.id) }.to raise_error(Ldp::Gone)
        expect { AdminSet.find(empty_adminset.id) }.to raise_error(Ldp::Gone)

        expect(flash[:notice]).to eq("Batch delete complete")
      end
    end

    context 'when user has edit access' do
      it "deletes collections with and without works in it and a none empty admin set is not deleted." do
        controller.batch = [collection1.id, collection2.id, adminset.id]
        delete :destroy_collection, params: { update_type: "delete_all" }
        expect { Collection.find(collection1.id) }.to raise_error(Ldp::Gone)
        expect { Collection.find(collection2.id) }.to raise_error(Ldp::Gone)
        expect { AdminSet.find(adminset.id) }.not_to raise_error(Ldp::Gone)

        expect(flash[:notice]).to include("One or more of the selected collections could not be deleted")
      end
    end

    context 'when user does not have edit access' do
      let(:user2) { create(:user) }

      let(:collection3) do
        create(:public_collection, title: ["User2's Collection"],
                                   description: ["Collection created by user2"],
                                   user: user2)
      end

      before do
        allow(controller).to receive(:current_user).and_return(user2)
      end

      it "fails to delete collections, and admin sets when user does not have edit access" do
        controller.batch = [collection1.id, collection2.id, adminset.id, empty_adminset.id]
        delete :destroy_collection, params: { update_type: "delete_all" }
        expect { Collection.find(collection1.id) }.not_to raise_error(Ldp::Gone)
        expect { Collection.find(collection2.id) }.not_to raise_error(Ldp::Gone)
        expect { AdminSet.find(adminset.id) }.not_to raise_error(Ldp::Gone)
        expect { AdminSet.find(empty_adminset.id) }.not_to raise_error(Ldp::Gone)
        expect(flash[:notice]).to include("One or more of the selected collections could not be deleted")
      end

      it "deletes collections where user has edit access, failing to delete those where user does not have edit access" do
        controller.batch = [collection1.id, collection2.id, collection3.id]
        delete :destroy_collection, params: { update_type: "delete_all" }
        expect { Collection.find(collection1.id) }.not_to raise_error(Ldp::Gone)
        expect { Collection.find(collection2.id) }.not_to raise_error(Ldp::Gone)
        expect { Collection.find(collection3.id) }.to raise_error(Ldp::Gone)
        expect(flash[:notice]).to include("One or more of the selected collections could not be deleted")
      end
    end
  end
end
