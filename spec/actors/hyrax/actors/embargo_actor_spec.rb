# frozen_string_literal: true
RSpec.describe Hyrax::Actors::EmbargoActor, :clean_repo do
  let(:actor) { described_class.new(work) }
  let(:restricted_vis) { 'restricted' }
  let(:authenticated_vis) { 'authenticated' }
  let(:public_vis) { 'open' }

  def embargo_manager(work)
    Hyrax::EmbargoManager
      .new(resource: Hyrax.query_service.find_by(id: work.id))
  end

  describe '#destroy' do
    context 'on a Valkyrie backed model' do
      let(:work) { FactoryBot.valkyrie_create(:hyrax_work, :under_embargo) }

      it 'releases the embargo' do
        expect { actor.destroy }
          .to change { embargo_manager(work).enforced? }
          .from(true)
          .to false
      end

      it 'adds embargo history' do
        expect { actor.destroy }
          .to change { embargo_manager(work).embargo.embargo_history }
          .to include start_with("An active embargo was deactivated")
      end

      it 'removes the embargo from the UI' do
        helper = Class.new { include Hyrax::EmbargoHelper }

        expect { actor.destroy }
          .to change { helper.new.assets_under_embargo }
          .from(contain_exactly(have_attributes(id: work.id)))
          .to be_empty
      end

      it 'changes the visibility' do
        expect { actor.destroy }
          .to change { work.visibility }
          .from(authenticated_vis)
          .to public_vis
      end

      context 'with an expired embargo' do
        let!(:work) { FactoryBot.valkyrie_create(:hyrax_work, :with_expired_enforced_embargo) }

        it 'releases the embargo' do
          expect { actor.destroy }
            .to change { embargo_manager(work).enforced? }
            .from(true)
            .to false
        end

        it 'adds embargo history' do
          expect { actor.destroy }
            .to change { embargo_manager(work).embargo.embargo_history }
            .to include start_with("An expired embargo was deactivated")
        end

        it 'removes the embargo from the UI' do
          helper = Class.new { include Hyrax::EmbargoHelper }

          work # create it

          expect { actor.destroy }
            .to change { helper.new.assets_under_embargo }
            .from(contain_exactly(have_attributes(id: work.id)))
            .to be_empty
        end
      end
    end

    context 'with an ActiveFedora model', :active_fedora do
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

      let(:embargo_release_date) { work.embargo.embargo_release_date }

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
