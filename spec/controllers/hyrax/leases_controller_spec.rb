# frozen_string_literal: true
RSpec.describe Hyrax::LeasesController do
  context 'with ActiveFedora', :active_fedora do
    let(:user) { create(:user) }
    let(:a_work) { create(:generic_work, user: user) }
    let(:not_my_work) { create(:generic_work) }

    before { sign_in user }

    describe '#index' do
      context 'when I am NOT a repository manager' do
        it 'redirects' do
          get :index
          expect(response).to redirect_to root_path
        end
      end
      context 'when I am a repository manager' do
        let(:user) { create(:user, groups: ['admin']) }

        it 'shows me the page' do
          expect(controller).to receive(:add_breadcrumb).with('Home', root_path)
          expect(controller).to receive(:add_breadcrumb).with('Dashboard', dashboard_path)
          expect(controller).to receive(:add_breadcrumb).with('Manage Leases', leases_path)

          get :index
          expect(response).to be_successful
          expect(response).to render_template('dashboard')
        end
      end
    end

    describe '#edit' do
      context 'when I do not have edit permissions for the object' do
        it 'redirects' do
          get :edit, params: { id: not_my_work }
          expect(response.status).to eq 302
          expect(flash[:alert]).to eq 'You are not authorized to access this page.'
        end
      end
      context 'when I have permission to edit the object' do
        it 'shows me the page' do
          expect(controller).to receive(:add_breadcrumb).with('Home', root_path)
          expect(controller).to receive(:add_breadcrumb).with('Dashboard', dashboard_path)
          expect(controller).to receive(:add_breadcrumb).with('Manage Leases', leases_path)
          expect(controller).to receive(:add_breadcrumb).with('Update Lease', '#')

          get :edit, params: { id: a_work }
          expect(response).to be_successful
          expect(response).to render_template('dashboard')
        end
      end
    end

    describe '#destroy' do
      context 'when I do not have edit permissions for the object' do
        it 'denies access' do
          get :destroy, params: { id: not_my_work }
          expect(response).to fail_redirect_and_flash(root_path, 'You are not authorized to access this page.')
        end
      end

      context 'when I have permission to edit the object' do
        context 'that has no files' do
          it 'deactivates the lease and redirects' do
            get :destroy, params: { id: a_work }
            expect(response).to redirect_to edit_lease_path(a_work)
          end
        end

        context 'with files' do
          before do
            a_work.members << create(:file_set)
            a_work.save!
          end

          it 'deactivates the lease and redirects' do
            get :destroy, params: { id: a_work }
            expect(response).to redirect_to confirm_permission_path(a_work)
          end
        end
      end
    end

    describe '#update' do
      context 'when I have permission to edit the object' do
        let(:file_set) { create(:file_set, visibility: Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC) }
        let(:expiration_date) { Time.zone.today + 2 }

        before do
          a_work.members << file_set
          a_work.visibility = Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_AUTHENTICATED
          a_work.visibility_during_lease = Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC
          a_work.visibility_after_lease = Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_AUTHENTICATED
          a_work.lease_expiration_date = expiration_date.to_s
          a_work.lease.save(validate: false)
          a_work.save(validate: false)
        end

        context 'with an expired lease' do
          let(:expiration_date) { Time.zone.today - 2 }

          it 'deactivates lease, do not update the visibility, and redirect' do
            patch :update, params: { batch_document_ids: [a_work.id], leases: {} }
            expect(a_work.reload.visibility).to eq Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_AUTHENTICATED
            expect(file_set.reload.visibility).to eq Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC
            expect(response).to redirect_to leases_path
          end
        end

        context 'with an expired lease' do
          let(:expiration_date) { Time.zone.today - 2 }

          it 'deactivates lease, update the visibility and redirect' do
            patch :update, params: { batch_document_ids: [a_work.id], leases: { '0' => { copy_visibility: a_work.id } } }
            expect(a_work.reload.visibility).to eq Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_AUTHENTICATED
            expect(file_set.reload.visibility).to eq Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_AUTHENTICATED
            expect(response).to redirect_to leases_path
          end
        end
      end
    end
  end

  context 'with Valkyrie' do
    let(:user) { create(:user) }
    let(:not_my_work) { valkyrie_create(:hyrax_work) }
    let(:a_work) do
      valkyrie_create(:hyrax_work,
                      edit_users: [user], members: [a_file_set], lease: a_lease,
                      visibility_setting: Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_AUTHENTICATED)
    end
    let(:a_file_set) { valkyrie_create(:hyrax_file_set, :public) }
    let(:expiration_date) { Time.zone.today + 2 }
    let(:a_lease) { valkyrie_create(:hyrax_lease, lease_expiration_date: expiration_date) }

    before { sign_in user }

    describe '#index' do
      context 'when I am NOT a repository manager' do
        it 'redirects' do
          get :index
          expect(response).to redirect_to root_path
        end
      end
      context 'when I am a repository manager' do
        let(:user) { create(:admin) }

        it 'shows me the page' do
          expect(controller).to receive(:add_breadcrumb).with('Home', root_path)
          expect(controller).to receive(:add_breadcrumb).with('Dashboard', dashboard_path)
          expect(controller).to receive(:add_breadcrumb).with('Manage Leases', leases_path)

          get :index
          expect(response).to be_successful
          expect(response).to render_template('dashboard')
        end
      end
    end

    describe '#edit' do
      context 'when I do not have edit permissions for the object' do
        it 'redirects' do
          get :edit, params: { id: not_my_work }
          expect(response.status).to eq 302
          expect(flash[:alert]).to eq 'You are not authorized to access this page.'
        end
      end
      context 'when I have permission to edit the object' do
        it 'shows me the page' do
          expect(controller).to receive(:add_breadcrumb).with('Home', root_path)
          expect(controller).to receive(:add_breadcrumb).with('Dashboard', dashboard_path)
          expect(controller).to receive(:add_breadcrumb).with('Manage Leases', leases_path)
          expect(controller).to receive(:add_breadcrumb).with('Update Lease', '#')

          get :edit, params: { id: a_work }
          expect(response).to be_successful
          expect(response).to render_template('dashboard')
        end
      end
    end

    describe '#destroy' do
      context 'when I do not have edit permissions for the object' do
        it 'denies access' do
          get :destroy, params: { id: not_my_work }
          expect(response).to fail_redirect_and_flash(root_path, 'You are not authorized to access this page.')
        end
      end

      context 'when I have permission to edit the object' do
        context 'that has no files' do
          let(:a_file_set) { nil }

          it 'deactivates the lease and redirects' do
            get :destroy, params: { id: a_work }
            expect(response).to redirect_to edit_lease_path(a_work)
          end
        end

        context 'with files' do
          it 'deactivates the lease and redirects' do
            get :destroy, params: { id: a_work }
            expect(response).to redirect_to confirm_permission_path(a_work)
          end
        end
      end
    end

    describe '#update' do
      context 'when I have permission to edit the object' do
        context 'with an expired lease' do
          let(:expiration_date) { Time.zone.today - 2 }

          it 'deactivates lease, do not update the visibility, and redirect' do
            patch :update, params: { batch_document_ids: [a_work.id], leases: {} }
            expect(Hyrax.query_service.find_by(id: a_work.id).visibility).to eq Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_AUTHENTICATED
            expect(Hyrax.query_service.find_by(id: a_file_set.id).visibility).to eq Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC
            expect(response).to redirect_to leases_path
          end

          it 'deactivates lease, update the visibility and redirect' do
            patch :update, params: { batch_document_ids: [a_work.id], leases: { '0' => { copy_visibility: a_work.id } } }
            expect(Hyrax.query_service.find_by(id: a_work.id).visibility).to eq Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_AUTHENTICATED
            expect(Hyrax.query_service.find_by(id: a_file_set.id).visibility).to eq Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_AUTHENTICATED
            expect(response).to redirect_to leases_path
          end
        end
      end
    end
  end
end
