# frozen_string_literal: true
RSpec.describe Hyrax::Actors::EmbargoActor do
  let(:actor) { described_class.new(work) }
  let(:authenticated_vis) { Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_AUTHENTICATED }
  let(:public_vis) { Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC }

  describe "#destroy" do
    let(:work) do
      FactoryBot.valkyrie_create(:hyrax_resource, :under_embargo)
    end

    before do
      work.visibility = authenticated_vis
      Hyrax::AccessControlList(work).save
    end

    it "removes the embargo" do
      expect { actor.destroy }
        .to change { Hyrax::EmbargoManager.new(resource: work).under_embargo? }
        .from(true)
        .to false
    end

    it "does not change the visibility" do
      expect { actor.destroy }
        .not_to change { work.visibility }
        .from authenticated_vis
    end

    context "with an expired embargo" do
      let(:work) do
        FactoryBot.valkyrie_create(:hyrax_resource, embargo: embargo)
      end

      let(:embargo) { FactoryBot.build(:hyrax_embargo) }

      before do
        allow(Hyrax::TimeService)
          .to receive(:time_in_utc)
          .and_return(work.embargo.embargo_release_date + 1)
      end

      it "leaves the embargo in place" do
        expect { actor.destroy }
          .not_to change { work.embargo.embargo_release_date }
      end

      it "releases the embargo" do
        expect { actor.destroy }
          .to change { Hyrax::EmbargoManager.new(resource: work).enforced? }
          .from(true)
          .to false
      end

      it "changes the visibility" do
        expect { actor.destroy }
          .to change { work.visibility }
          .from(authenticated_vis)
          .to public_vis
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
