# frozen_string_literal: true
RSpec.describe Hyrax::BatchEditsController, type: :controller do
  let(:user) { create(:user) }

  before do
    sign_in user
    allow_any_instance_of(User).to receive(:groups).and_return([])
    request.env["HTTP_REFERER"] = 'test.host/original_page'
  end

  shared_examples('tests that edit page loads') do
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

  shared_context('with set batch and permissions') do
    before do
      # TODO: why aren't we just submitting batch_document_ids[] as a parameter?
      controller.batch = [one.id, two.id, three.id]
      expect(controller).to receive(:can?).with(:edit, one.id).and_return(true)
      expect(controller).to receive(:can?).with(:edit, two.id).and_return(true)
      expect(controller).to receive(:can?).with(:edit, three.id).and_return(false)
    end
  end

  describe "#edit" do
    include_context 'with set batch and permissions'

    context 'with ActiveFedora works', :active_fedora do
      let(:one) { create(:work, creator: ["Fred"], title: ["abc"], language: ['en']) }
      let(:two) { create(:work, creator: ["Wilma"], title: ["abc2"], publisher: ['Rand McNally'], language: ['en'], resource_type: ['bar']) }
      let(:three) { create(:work, creator: ["Dino"], title: ["abc3"]) }

      include_examples 'tests that edit page loads'
    end
    context "with work resources" do
      let(:one) { FactoryBot.valkyrie_create(:monograph, creator: ["Fred"], title: ["abc"], language: ['en']) }
      let(:two) { FactoryBot.valkyrie_create(:monograph, creator: ["Wilma"], title: ["abc2"], publisher: ['Rand McNally'], language: ['en'], resource_type: ['bar']) }
      let(:three) { FactoryBot.valkyrie_create(:monograph, creator: ["Dino"], title: ["abc3"]) }

      include_examples 'tests that edit page loads'
    end
  end

  describe "update" do
    let(:permission_template) { create(:permission_template, source_id: admin_set.id) }
    let!(:workflow) { create(:workflow, allows_access_grant: true, active: true, permission_template_id: permission_template.id) }

    let(:release_date) { Time.zone.today + 2 }

    let(:mycontroller) { "hyrax/my/works" }

    include_context 'with set batch and permissions'

    context "with ActiveFedora works", :active_fedora do
      let(:admin_set) { create(:admin_set) }
      let!(:one) { create(:work, admin_set_id: admin_set.id, creator: ["Fred"], title: ["abc"], language: ['en'], user: user) }
      let!(:two) { create(:work, admin_set_id: admin_set.id, creator: ["Fred"], title: ["abc"], language: ['en'], user: user) }
      let!(:three) { create(:work, admin_set_id: admin_set.id, creator: ["Fred"], title: ["abc"], language: ['en']) }
      let!(:file_set) { create(:file_set, creator: ["Fred"]) }

      before do
        one.members << file_set
        one.save!
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
          put :update, params: { update_type: "update", generic_work: { permissions_attributes: { "0" => { type: 'person', access: 'read', name: 'foo@bar.com' } } } }
          expect(response).to be_redirect

          work1 = GenericWork.find(one.id)
          expect(work1.read_users).to include "foo@bar.com"
          expect(work1.file_sets.map(&:read_users)).to eq [["foo@bar.com"]]

          expect(GenericWork.find(two.id).read_users).to eq ["foo@bar.com"]
          expect(GenericWork.find(three.id).read_users).to eq []
        end
      end
    end

    context "with work resources" do
      let(:admin_set) { FactoryBot.valkyrie_create(:hyrax_admin_set) }
      let!(:one) { valkyrie_create(:monograph, :with_member_file_sets, admin_set_id: admin_set.id, creator: ["Fred"], title: ["abc"], language: ['en'], depositor: user.user_key) }
      let!(:two) { valkyrie_create(:monograph, admin_set_id: admin_set.id, creator: ["Fred"], title: ["abc"], language: ['en'], depositor: user.user_key) }
      let!(:three) { valkyrie_create(:monograph, admin_set_id: admin_set.id, creator: ["Fred"], title: ["abc"], language: ['en']) }
      let(:form_class) { Hyrax.config.use_valkyrie? ? Hyrax::Forms::ResourceBatchEditForm : Hyrax::Forms::BatchEditForm }
      let(:param_key) { form_class.model_class.model_name.param_key }
      let(:work1) { Hyrax.query_service.find_by(id: one.id) }
      let(:work2) { Hyrax.query_service.find_by(id: two.id) }
      let(:work3) { Hyrax.query_service.find_by(id: three.id) }

      it "is successful" do
        put :update, params: { update_type: "delete_all" }
        expect(response).to redirect_to(dashboard_path(locale: 'en'))
        expect { work1 }.to raise_error(Valkyrie::Persistence::ObjectNotFoundError)
        expect { work2 }.to raise_error(Valkyrie::Persistence::ObjectNotFoundError)
        expect { work3 }.not_to raise_error(Valkyrie::Persistence::ObjectNotFoundError)
      end

      it "redirects to the return controller" do
        put :update, params: { update_type: "delete_all", return_controller: mycontroller }
        expect(response).to redirect_to(Hyrax::Engine.routes.url_for(controller: mycontroller, only_path: true, locale: 'en'))
      end

      it "updates the records" do
        put :update, params: { update_type: "update", "#{param_key}": { subject: ["zzz"] } }
        expect(response).to be_redirect
        expect(work1.subject).to eq ["zzz"]
        expect(work2.subject).to eq ["zzz"]
        expect(work3.subject).to be_empty
      end

      it "updates permissions" do
        put :update, params: { update_type: "update", "#{param_key}": { visibility: "authenticated" } }
        expect(response).to be_redirect

        expect(work1.visibility).to eq "authenticated"
        expect(Hyrax.query_service.find_many_by_ids(ids: work1.member_ids).map(&:visibility)).to eq ["authenticated", "authenticated"]

        expect(work2.visibility).to eq "authenticated"
        expect(work3.visibility).to eq "restricted"
      end

      it 'creates leases' do
        put :update, params: { update_type: "update",
                               "#{param_key}": { visibility: "lease", lease_expiration_date: release_date, visibility_during_lease: 'open', visibility_after_lease: 'restricted' } }
        expect(response).to be_redirect

        expect(work1.visibility).to eq "open"
        expect(work1.lease.visibility_during_lease).to eq 'open'
        expect(work1.lease.visibility_after_lease).to eq 'restricted'
        expect(work1.lease.lease_expiration_date).to eq release_date.to_s
        file_sets = Hyrax.query_service.find_many_by_ids(ids: work1.member_ids)
        expect(file_sets.map(&:visibility)).to eq ['open', 'open']
        expect(file_sets.map(&:lease).map(&:visibility_during_lease)).to eq ['open', 'open']
        expect(file_sets.map(&:lease).map(&:visibility_after_lease)).to eq ['restricted', 'restricted']
        expect(file_sets.map(&:lease).map(&:lease_expiration_date)).to eq [release_date.to_s, release_date.to_s]

        expect(work2.visibility).to eq 'open'
        expect(work2.lease.visibility_during_lease).to eq 'open'
        expect(work2.lease.visibility_after_lease).to eq 'restricted'
        expect(work2.lease.lease_expiration_date).to eq release_date.to_s

        expect(work3.visibility).to eq 'restricted'
        expect(work3.lease).to be_nil
      end

      it 'creates embargoes' do
        put :update, params: { update_type: "update",
                               "#{param_key}": { visibility: "embargo", embargo_release_date: release_date, visibility_during_embargo: 'authenticated', visibility_after_embargo: 'open' } }
        expect(response).to be_redirect

        expect(work1.visibility).to eq "authenticated"
        expect(work1.embargo.visibility_during_embargo).to eq 'authenticated'
        expect(work1.embargo.visibility_after_embargo).to eq 'open'
        expect(work1.embargo.embargo_release_date).to eq release_date.to_s
        file_sets = Hyrax.query_service.find_many_by_ids(ids: work1.member_ids)
        expect(file_sets.map(&:visibility)).to eq ['authenticated', 'authenticated']
        expect(file_sets.map(&:embargo).map(&:visibility_during_embargo)).to eq ['authenticated', 'authenticated']
        expect(file_sets.map(&:embargo).map(&:visibility_after_embargo)).to eq ['open', 'open']
        expect(file_sets.map(&:embargo).map(&:embargo_release_date)).to eq [release_date.to_s, release_date.to_s]

        expect(work2.visibility).to eq 'authenticated'
        expect(work2.embargo.visibility_during_embargo).to eq 'authenticated'
        expect(work2.embargo.visibility_after_embargo).to eq 'open'
        expect(work2.embargo.embargo_release_date).to eq release_date.to_s

        expect(work3.visibility).to eq 'restricted'
        expect(work3.embargo).to be_nil
      end

      context 'with roles' do
        it 'updates roles' do
          put :update, params: { update_type: "update", "#{param_key}": { permissions_attributes: { "0" => { type: 'person', access: 'read', name: 'foo@bar.com' } } } }
          expect(response).to be_redirect

          expect(work1.read_users.to_a).to include "foo@bar.com"
          expect(Hyrax.query_service.find_many_by_ids(ids: work1.member_ids).map(&:read_users).map(&:to_a)).to eq [["foo@bar.com"], ["foo@bar.com"]]

          expect(work2.read_users.to_a).to eq ["foo@bar.com"]
          expect(work3.read_users.to_a).to eq []
        end
      end
    end
  end

  describe "#destroy_collection" do
    shared_context('with signed-in user, set batch, and permissions') do
      before do
        sign_in user2
        controller.batch = [collection1.id, collection3.id]
        allow(controller).to receive(:can?).with(:edit, collection1.id).and_return(false)
        allow(controller).to receive(:can?).with(:edit, collection2.id).and_return(false)
        allow(controller).to receive(:can?).with(:edit, collection3.id).and_return(true)
      end
    end

    context 'with ActiveFedora objects', :active_fedora do
      let(:collection1) { valkyrie_create(:hyrax_collection, :public, title: ["My First Collection"], user: user) }
      let(:collection2) { valkyrie_create(:hyrax_collection, :public, title: ["My Other Collection"], user: user) }
      let!(:work1) { valkyrie_create(:hyrax_work, title: ["First of the Assets"], member_of_collection_ids: [collection1.id], depositor: user.user_key) }

      context 'when user has edit access' do
        before do
          controller.batch = [collection1.id.to_s, collection2.id.to_s]
          allow(controller).to receive(:can?).with(:edit, collection1.id.to_s).and_return(true)
          allow(controller).to receive(:can?).with(:edit, collection2.id.to_s).and_return(true)
        end

        it "deletes collections with and without works in it" do
          delete :destroy_collection, params: { update_type: "delete_all" }
          expect { Collection.find(collection1.id.to_s) }.to raise_error(Ldp::Gone)
          expect { Collection.find(collection2.id.to_s) }.to raise_error(Ldp::Gone)
        end
      end

      context 'when user does not have edit access' do
        let(:user2) { create(:user) }
        let(:collection3) { valkyrie_create(:hyrax_collection, :public, title: ["User2's Collection"], user: user2) }

        include_context 'with signed-in user, set batch, and permissions'
        it "deletes collections where user has edit access, failing to delete those where user does not have edit access" do
          delete :destroy_collection, params: { update_type: "delete_all" }
          expect(Collection.exists?(collection1.id.to_s)).to eq true
          expect(Collection.exists?(collection2.id.to_s)).to eq true
          expect { Collection.find(collection3.id.to_s) }.to raise_error(Ldp::Gone)
        end
      end
    end

    context 'with work resources' do
      let(:collection1) { valkyrie_create(:hyrax_collection, title: ["My First Collection"], edit_users: [user.user_key]) }
      let(:collection2) { valkyrie_create(:hyrax_collection, title: ["My Other Collection"], edit_users: [user.user_key]) }
      let!(:work1) { valkyrie_create(:monograph, title: ["First of the Assets"], member_of_collection_ids: [collection1.id], depositor: user.user_key, edit_users: [user.user_key]) }
      let(:work2)  { valkyrie_create(:monograph, title: ["Second of the Assets"], depositor: user.user_key, edit_users: [user.user_key]) }

      context 'when user has edit access' do
        before do
          controller.batch = [collection1.id, collection2.id]
          allow(controller).to receive(:can?).with(:edit, collection1.id).and_return(true)
          allow(controller).to receive(:can?).with(:edit, collection2.id).and_return(true)
        end

        it "deletes collections with and without works in it" do
          delete :destroy_collection, params: { update_type: "delete_all" }
          expect { Hyrax.query_service.find_by(id: collection1.id) }.to raise_error(Valkyrie::Persistence::ObjectNotFoundError)
          expect { Hyrax.query_service.find_by(id: collection2.id) }.to raise_error(Valkyrie::Persistence::ObjectNotFoundError)
        end
      end

      context 'when user does not have edit access' do
        let(:user2) { create(:user) }
        let(:collection3) { valkyrie_create(:hyrax_collection, title: ["User2's Collection"], edit_users: [user2]) }

        include_context 'with signed-in user, set batch, and permissions'

        it "deletes collections where user has edit access, failing to delete those where user does not have edit access" do
          delete :destroy_collection, params: { update_type: "delete_all" }
          expect { Hyrax.query_service.find_by(id: collection1.id) }.not_to raise_error(Valkyrie::Persistence::ObjectNotFoundError)
          expect { Hyrax.query_service.find_by(id: collection2.id) }.not_to raise_error(Valkyrie::Persistence::ObjectNotFoundError)
          expect { Hyrax.query_service.find_by(id: collection3.id) }.to raise_error(Valkyrie::Persistence::ObjectNotFoundError)
        end
      end
    end
  end
end
