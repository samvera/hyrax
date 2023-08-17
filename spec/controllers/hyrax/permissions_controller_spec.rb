# frozen_string_literal: true
RSpec.describe Hyrax::PermissionsController do
  let(:user) { FactoryBot.create(:user) }

  before { sign_in user }

  context 'with legacy AF models' do
    describe '#confirm_access' do
      let(:work) { FactoryBot.valkyrie_create(:monograph, edit_users: [user]) }

      it 'draws the page' do
        get :confirm_access, params: { id: work }
        expect(response).to be_successful
      end
    end

    describe '#copy' do
      let(:work) { FactoryBot.valkyrie_create(:monograph, edit_users: [user]) }

      it 'adds a worker to the queue' do
        expect { post :copy, params: { id: work } }
          .to have_enqueued_job(VisibilityCopyJob)
          .with(work)

        expect(response).to redirect_to main_app.hyrax_monograph_path(work, locale: 'en')
        expect(flash[:notice]).to eq 'Updating file permissions. This may take a few minutes. You may want to refresh your browser or return to this record later to see the updated file permissions.'
      end
    end

    describe '#copy_access' do
      let(:work) { FactoryBot.valkyrie_create(:monograph, edit_users: [user]) }

      it 'adds VisibilityCopyJob to the queue' do
        expect { post :copy_access, params: { id: work } }
          .to have_enqueued_job(VisibilityCopyJob)
          .with(work)

        expect(response).to redirect_to main_app.hyrax_monograph_path(work, locale: 'en')
        expect(flash[:notice]).to eq 'Updating file access levels. This may take a few minutes. ' \
                                     'You may want to refresh your browser or return to this record ' \
                                     'later to see the updated file access levels.'
      end

      it 'adds InheritPermisionsJob to the queue' do
        expect { post :copy_access, params: { id: work } }
          .to have_enqueued_job(InheritPermissionsJob)
          .with(work)
      end
    end
  end
end
