# frozen_string_literal: true
RSpec.describe Hyrax::Actors::EmbargoActor, :active_fedora do
  let(:actor) { described_class.new(work) }
  let(:authenticated_vis) { Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_AUTHENTICATED }
  let(:public_vis) { Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC }

  describe '#destroy' do
    context 'on a Valkyrie backed model', if: Hyrax.config.use_valkyrie? do
      let(:work) { FactoryBot.valkyrie_create(:hyrax_resource, embargo: embargo) }
      let(:embargo) { FactoryBot.create(:hyrax_embargo) }
      let(:embargo_manager) { Hyrax::EmbargoManager.new(resource: work) }
      let(:active_embargo_release_date) { work.embargo.embargo_release_date }

      before do
        work.visibility = authenticated_vis
        Hyrax::AccessControlList(work).save
      end

      it 'removes the embargo' do
        actor.destroy

        expect(work.embargo.embargo_release_date).to eq nil
        expect(work.embargo.visibility_after_embargo).to eq nil
        expect(work.embargo.visibility_during_embargo).to eq nil
      end

      it 'releases the embargo' do
        expect { actor.destroy }
          .to change { embargo_manager.enforced? }
          .from(true)
          .to false
      end

      it 'changes the embargo release date' do
        expect { actor.destroy }
          .to change { work.embargo.embargo_release_date }
          .from(active_embargo_release_date)
          .to nil
      end

      it 'changes the visibility' do
        expect { actor.destroy }
          .to change { work.visibility }
          .from(authenticated_vis)
          .to public_vis
      end

      context 'with an expired embargo' do
        let(:work) { valkyrie_create(:hyrax_resource, embargo: expired_embargo) }
        let(:expired_embargo) { create(:hyrax_embargo, :expired) }
        let(:embargo_manager) { Hyrax::EmbargoManager.new(resource: work) }
        let(:embargo_release_date) { work.embargo.embargo_release_date }

        it 'removes the embargo' do
          expect { actor.destroy }
            .to change { work.embargo.embargo_release_date }
            .from(embargo_release_date)
            .to nil
        end
      end
    end

    context 'with an ActiveFedora model', unless: Hyrax.config.use_valkyrie? do
      let(:work) do
        GenericWork.new do |work|
          work.apply_depositor_metadata 'foo'
          work.title = ['test']
          work.visibility =
            work.visibility_during_embargo = authenticated_vis
          work.visibility_after_embargo = public_vis
          work.embargo_release_date = embargo_release_date.to_s
          work.save(validate: false)
        end
      end

      context 'with an active embargo' do
        let(:embargo_release_date) { Time.zone.today + 2 }

        it 'removes the embargo' do
          actor.destroy
          expect(work.reload.embargo_release_date).to be_nil
          expect(work.visibility).to eq authenticated_vis
        end
      end

      context 'with an expired embargo' do
        let(:embargo_release_date) { Time.zone.today - 2 }

        it 'removes the embargo' do
          actor.destroy
          expect(work.reload.embargo_release_date).to be_nil
          expect(work.visibility).to eq public_vis
        end
      end
    end
  end
end
