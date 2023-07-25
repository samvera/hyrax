# frozen_string_literal: true
RSpec.describe Hyrax::Actors::EmbargoActor do
  let(:actor) { described_class.new(work) }
  let(:authenticated_vis) { Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_AUTHENTICATED }
  let(:public_vis) { Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC }

  describe "#destroy" do
    let(:work) do
      FactoryBot.valkyrie_create(:hyrax_resource, embargo: embargo)
    end
    let(:embargo) { FactoryBot.create(:hyrax_embargo) }

    before do
      work.visibility = authenticated_vis
      Hyrax::AccessControlList(work).save
    end

    it "removes the embargo" do
      skip 'embargogeddon' do
        expect { actor.destroy }
          .to change { Hyrax::EmbargoManager.new(resource: work).under_embargo? }
          .from(true)
          .to false
      end
    end

    it "change the visibility" do
      skip 'embargogeddon' do
        expect { actor.destroy }
          .to change { work.visibility }
          .from(authenticated_vis)
          .to public_vis
      end
    end

    context "with an expired embargo" do
      let(:work) do
        FactoryBot.valkyrie_create(:hyrax_resource, embargo: embargo)
      end

      let(:embargo) { FactoryBot.create(:hyrax_embargo) }
      let(:embargo_manager) { Hyrax::EmbargoManager.new(resource: work) }
      let(:embargo_release_date) { work.embargo.embargo_release_date }

      before do
        allow(Hyrax::TimeService)
          .to receive(:time_in_utc)
          .and_return(embargo_release_date.to_datetime + 1)
        expect(embargo_manager.under_embargo?).to eq false
      end

      it "removes the embargo" do
        skip 'embargogeddon' do
          expect { actor.destroy }
            .to change { work.embargo.embargo_release_date }
            .from(embargo_release_date)
            .to nil
        end
      end

      it "releases the embargo" do
        skip 'embargogeddon' do
          expect(embargo_manager.enforced?).to eq true
          expect { actor.destroy }
            .to change { embargo_manager.enforced? }
            .from(true)
            .to false
        end
      end

      it "changes the visibility" do
        skip 'embargogeddon' do
          expect(work.embargo.visibility_after_embargo).to eq public_vis
          expect { actor.destroy }
            .to change { work.visibility }
            .from(authenticated_vis)
            .to public_vis
        end
      end
    end

    context "with a ActiveFedora model" do
      let(:work) do
        GenericWork.new do |work|
          work.apply_depositor_metadata 'foo'
          work.title = ["test"]
          work.visibility =
            work.visibility_during_embargo = authenticated_vis
          work.visibility_after_embargo = public_vis
          work.embargo_release_date = release_date.to_s
          work.save(validate: false)
        end
      end

      context "with an active embargo" do
        let(:release_date) { Time.zone.today + 2 }

        it "removes the embargo" do
          actor.destroy
          expect(work.reload.embargo_release_date).to be_nil
          expect(work.visibility).to eq authenticated_vis
        end
      end

      context 'with an expired embargo' do
        let(:release_date) { Time.zone.today - 2 }

        it "removes the embargo" do
          actor.destroy
          expect(work.reload.embargo_release_date).to be_nil
          expect(work.visibility).to eq public_vis
        end
      end
    end
  end
end
