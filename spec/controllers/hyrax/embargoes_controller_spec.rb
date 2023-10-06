# frozen_string_literal: true
RSpec.describe Hyrax::EmbargoesController do
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
          expect(controller).to receive(:add_breadcrumb).with('Manage Embargoes', embargoes_path)
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
          expect(controller).to receive(:add_breadcrumb).with('Manage Embargoes', embargoes_path)
          expect(controller).to receive(:add_breadcrumb).with('Update Embargo', '#')
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
          it 'deactivates embargo and redirects' do
            get :destroy, params: { id: a_work }
            expect(response).to redirect_to edit_embargo_path(a_work)
          end
        end

        context 'that has files' do
          before do
            a_work.members << create(:file_set)
            a_work.save!
          end

          it 'deactivates embargo and checks to see if we want to copy the visibility to files' do
            get :destroy, params: { id: a_work }
            expect(response).to redirect_to confirm_permission_path(a_work)
          end
        end
      end
    end

    describe '#update' do
      context 'when I have permission to edit the object' do
        let(:file_set) { create(:file_set, visibility: Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_AUTHENTICATED) }
        let(:release_date) { Time.zone.today + 2 }

        before do
          a_work.members << file_set
          a_work.visibility = Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_AUTHENTICATED
          a_work.visibility_during_embargo = Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_AUTHENTICATED
          a_work.visibility_after_embargo = Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC
          a_work.embargo_release_date = release_date.to_s
          a_work.embargo.save(validate: false)
          a_work.save(validate: false)
        end

        context 'with an expired embargo' do
          let(:release_date) { Time.zone.today - 2 }

          it 'deactivates embargo, do not update the file set visibility, and redirect' do
            patch :update, params: { batch_document_ids: [a_work.id], embargoes: {} }
            expect(a_work.reload.visibility).to eq Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC
            expect(file_set.reload.visibility).to eq Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_AUTHENTICATED
            expect(response).to redirect_to embargoes_path
            expect(flash[:notice]).to be_present
          end
        end

        context 'with an expired embargo' do
          let(:release_date) { Time.zone.today - 2 }

          it 'deactivates embargo, update the visibility and redirect' do
            patch :update, params: { batch_document_ids: [a_work.id], embargoes: { '0' => { copy_visibility: a_work.id } } }
            expect(a_work.reload.visibility).to eq Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC
            expect(file_set.reload.visibility).to eq Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC
            expect(response).to redirect_to embargoes_path
            expect(flash[:notice]).to be_present
          end
        end

        context 'with an expired embargo and filesets in batch_document_ids and in embargoes' do
          let(:file_set2) { create(:file_set, id: 'fileset_2', visibility: Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_AUTHENTICATED) }
          let(:file_set3) { create(:file_set, id: 'fileset_3', visibility: Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_AUTHENTICATED) }
          let(:release_date) { Time.zone.today - 2 }
          let(:batch) { [file_set2.id, a_work.id] }
          before do
            file_set2.visibility = Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_AUTHENTICATED
            file_set2.visibility_during_embargo = Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_AUTHENTICATED
            file_set2.visibility_after_embargo = Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC
            file_set2.embargo_release_date = release_date.to_s
            file_set2.embargo.save(validate: false)
            file_set2.save(validate: false)
            file_set3.visibility = Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_AUTHENTICATED
            file_set3.visibility_during_embargo = Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_AUTHENTICATED
            file_set3.visibility_after_embargo = Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC
            file_set3.embargo_release_date = release_date.to_s
            file_set3.embargo.save(validate: false)
            file_set3.save(validate: false)
          end

          it 'deactivates embargo, updates the visibility and redirects' do
            allow(controller).to receive(:filter_docs_with_edit_access!).and_return(true)
            patch :update, params: { batch_document_ids: batch, embargoes: { '0' => { copy_visibility: file_set2.id }, '1' => { copy_visibility: a_work.id } } }
            expect(a_work.reload.visibility).to eq Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC
            expect(file_set.reload.visibility).to eq Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC
            expect(file_set2.reload.visibility).to eq Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC
            expect(file_set3.reload.visibility).to eq Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_AUTHENTICATED
            expect(response).to redirect_to embargoes_path
            expect(flash[:notice]).to be_present
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
                      edit_users: [user], members: [a_file_set], embargo: an_embargo,
                      visibility_setting: Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_AUTHENTICATED)
    end
    let(:a_file_set) { valkyrie_create(:hyrax_file_set, :public) }
    let(:release_date) { Time.zone.today + 2 }
    let(:an_embargo) { valkyrie_create(:hyrax_embargo, embargo_release_date: release_date) }

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
          expect(controller).to receive(:add_breadcrumb).with('Manage Embargoes', embargoes_path)
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
          expect(controller).to receive(:add_breadcrumb).with('Manage Embargoes', embargoes_path)
          expect(controller).to receive(:add_breadcrumb).with('Update Embargo', '#')
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

          it 'deactivates embargo and redirects' do
            get :destroy, params: { id: a_work }
            expect(response).to redirect_to edit_embargo_path(a_work)
          end
        end

        context 'that has files' do
          it 'deactivates embargo and checks to see if we want to copy the visibility to files' do
            get :destroy, params: { id: a_work }
            expect(response).to redirect_to confirm_permission_path(a_work)
          end
        end
      end
    end

    describe '#update' do
      context 'when I have permission to edit the object' do
        let(:a_file_set) { valkyrie_create(:hyrax_file_set, :authenticated) }

        context 'with an expired embargo' do
          let(:release_date) { Time.zone.today - 2 }

          it 'deactivates embargo, do not update the file set visibility, and redirect' do
            patch :update, params: { batch_document_ids: [a_work.id], embargoes: {} }
            expect(Hyrax.query_service.find_by(id: a_work.id).visibility).to eq Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC
            expect(Hyrax.query_service.find_by(id: a_file_set.id).visibility).to eq Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_AUTHENTICATED
            expect(response).to redirect_to embargoes_path
            expect(flash[:notice]).to be_present
          end

          it 'deactivates embargo, update the visibility and redirect' do
            patch :update, params: { batch_document_ids: [a_work.id], embargoes: { '0' => { copy_visibility: a_work.id } } }
            expect(Hyrax.query_service.find_by(id: a_work.id).visibility).to eq Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC
            expect(Hyrax.query_service.find_by(id: a_file_set.id).visibility).to eq Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC
            expect(response).to redirect_to embargoes_path
            expect(flash[:notice]).to be_present
          end

          context 'with filesets in batch_document_ids and in embargoes' do
            let(:a_2nd_file_set) { valkyrie_create(:hyrax_file_set, :authenticated, embargo: valkyrie_create(:hyrax_embargo, embargo_release_date: release_date)) }
            let(:a_3rd_file_set) { valkyrie_create(:hyrax_file_set, :authenticated, embargo: valkyrie_create(:hyrax_embargo, embargo_release_date: release_date)) }
            let(:batch) { [a_2nd_file_set.id, a_work.id] }

            it 'deactivates embargo, updates the visibility and redirects' do
              allow(controller).to receive(:filter_docs_with_edit_access!).and_return(true)
              patch :update, params: { batch_document_ids: batch, embargoes: { '0' => { copy_visibility: a_2nd_file_set.id }, '1' => { copy_visibility: a_work.id } } }
              expect(Hyrax.query_service.find_by(id: a_work.id).visibility).to eq Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC
              expect(Hyrax.query_service.find_by(id: a_file_set.id).visibility).to eq Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC
              expect(Hyrax.query_service.find_by(id: a_2nd_file_set.id).visibility).to eq Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC
              expect(Hyrax.query_service.find_by(id: a_3rd_file_set.id).visibility).to eq Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_AUTHENTICATED
              expect(response).to redirect_to embargoes_path
              expect(flash[:notice]).to be_present
            end
          end
        end
      end
    end
  end
end
