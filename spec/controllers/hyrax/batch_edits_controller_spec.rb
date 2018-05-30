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
      expect(controller).to receive(:add_breadcrumb).with('Home', Hyrax::Engine.routes.url_helpers.root_path(locale: 'en'))
      expect(controller).to receive(:add_breadcrumb).with(I18n.t('hyrax.dashboard.title'), Hyrax::Engine.routes.url_helpers.dashboard_path(locale: 'en'))
      expect(controller).to receive(:add_breadcrumb).with(I18n.t('hyrax.dashboard.my.works'), Hyrax::Engine.routes.url_helpers.my_works_path(locale: 'en'))
      get :edit
      expect(response).to be_successful
      expect(response).to render_template('dashboard')
      expect(assigns[:form].model.creator).to match_array ["Fred", "Wilma"]
    end
  end

  describe "update" do
    let(:user) { build(:user) }
    let(:admin_set) { create(:admin_set) }
    let(:permission_template) { create(:permission_template, source_id: admin_set.id) }
    let!(:workflow) { create(:workflow, allows_access_grant: true, active: true, permission_template_id: permission_template.id) }
    let!(:one) do
      create(:work, admin_set_id: admin_set.id, creator: ["Fred"], title: ["abc"], language: ['en'], user: user)
    end

    let!(:two) do
      create(:work, admin_set_id: admin_set.id, creator: ["Fred"], title: ["abc"], language: ['en'], user: user)
    end

    let!(:three) do
      create(:work, admin_set_id: admin_set.id, creator: ["Fred"], title: ["abc"], language: ['en'])
    end

    let!(:file_set) do
      create(:file_set, creator: ["Fred"])
    end

    let(:release_date) { Time.zone.today + 2 }

    let(:mycontroller) { "hyrax/my/works" }

    before do
      one.members << file_set
      one.save!

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
      put :update, params: { update_type: "update", generic_work: { visibility: "authenticated" } }
      expect(response).to be_redirect

      work1 = GenericWork.find(one.id)
      expect(work1.visibility).to eq "authenticated"
      expect(work1.file_sets.map(&:visibility)).to eq ["authenticated"]

      expect(GenericWork.find(two.id).visibility).to eq "authenticated"
      expect(GenericWork.find(three.id).visibility).to eq "restricted"
    end

    it 'creates leases' do
      put :update, params: { update_type: "update",
                             generic_work: { visibility: "lease", lease_expiration_date: release_date, visibility_during_lease: 'open', visibility_after_lease: 'restricted' } }
      expect(response).to be_redirect

      work1 = GenericWork.find(one.id)
      expect(work1.visibility).to eq "open"
      expect(work1.visibility_during_lease).to eq 'open'
      expect(work1.visibility_after_lease).to eq 'restricted'
      expect(work1.lease_expiration_date).to eq release_date
      expect(work1.file_sets.map(&:visibility)).to eq ['open']
      expect(work1.file_sets.map(&:visibility_during_lease)).to eq ['open']
      expect(work1.file_sets.map(&:visibility_after_lease)).to eq ['restricted']
      expect(work1.file_sets.map(&:lease_expiration_date)).to eq [release_date]

      work2 = GenericWork.find(two.id)
      expect(work2.visibility).to eq 'open'
      expect(work2.visibility_during_lease).to eq 'open'
      expect(work2.visibility_after_lease).to eq 'restricted'
      expect(work2.lease_expiration_date).to eq release_date

      work3 = GenericWork.find(three.id)
      expect(work3.visibility).to eq 'restricted'
      expect(work3.visibility_during_lease).to be_nil
      expect(work3.visibility_after_lease).to be_nil
      expect(work3.lease_expiration_date).to be_nil
    end

    it 'creates embargoes' do
      put :update, params: { update_type: "update",
                             generic_work: { visibility: "embargo", embargo_release_date: release_date, visibility_during_embargo: 'authenticated', visibility_after_embargo: 'open' } }
      expect(response).to be_redirect

      work1 = GenericWork.find(one.id)
      expect(work1.visibility).to eq "authenticated"
      expect(work1.visibility_during_embargo).to eq 'authenticated'
      expect(work1.visibility_after_embargo).to eq 'open'
      expect(work1.embargo_release_date).to eq release_date
      expect(work1.file_sets.map(&:visibility)).to eq ['authenticated']
      expect(work1.file_sets.map(&:visibility_during_embargo)).to eq ['authenticated']
      expect(work1.file_sets.map(&:visibility_after_embargo)).to eq ['open']
      expect(work1.file_sets.map(&:embargo_release_date)).to eq [release_date]

      work2 = GenericWork.find(two.id)
      expect(work2.visibility).to eq 'authenticated'
      expect(work2.visibility_during_embargo).to eq 'authenticated'
      expect(work2.visibility_after_embargo).to eq 'open'
      expect(work2.embargo_release_date).to eq release_date

      work3 = GenericWork.find(three.id)
      expect(work3.visibility).to eq 'restricted'
      expect(work3.visibility_during_embargo).to be_nil
      expect(work3.visibility_after_embargo).to be_nil
      expect(work3.embargo_release_date).to be_nil
    end

    context 'with roles' do
      it 'updates roles' do
        put :update, params: { update_type: "update", generic_work: { permissions_attributes: [{ type: 'person', access: 'read', name: 'foo@bar.com' }] } }
        expect(response).to be_redirect

        work1 = GenericWork.find(one.id)
        expect(work1.read_users).to include "foo@bar.com"
        expect(work1.file_sets.map(&:read_users)).to eq [["foo@bar.com"]]

        expect(GenericWork.find(two.id).read_users).to eq ["foo@bar.com"]
        expect(GenericWork.find(three.id).read_users).to eq []
      end
    end
  end

  describe "#destroy_collection" do
    let(:user) { create(:user) }

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
      it "deletes collections with and without works in it" do
        controller.batch = [collection1.id, collection2.id]
        delete :destroy_collection, params: { update_type: "delete_all" }
        expect { Collection.find(collection1.id) }.to raise_error(Ldp::Gone)
        expect { Collection.find(collection2.id) }.to raise_error(Ldp::Gone)
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

      it "fails to delete collections when user does not have edit access" do
        controller.batch = [collection1.id, collection3.id]
        delete :destroy_collection, params: { update_type: "delete_all" }
        expect(Collection.exists?(collection1.id)).to eq true
        expect(Collection.exists?(collection2.id)).to eq true
      end

      it "deletes collections where user has edit access, failing to delete those where user does not have edit access" do
        controller.batch = [collection1.id, collection3.id]
        delete :destroy_collection, params: { update_type: "delete_all" }
        expect(Collection.exists?(collection1.id)).to eq true
        expect(Collection.exists?(collection2.id)).to eq true
        expect { Collection.find(collection3.id) }.to raise_error(Ldp::Gone)
      end
    end
  end
end
