# frozen_string_literal: true
RSpec.describe Hyrax::Actors::LeaseActor, :active_fedora do
  let(:actor) { described_class.new(work) }
  let(:authenticated_vis) { Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_AUTHENTICATED }
  let(:public_vis) { Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC }
  let(:private_vis) { Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE }

  describe "#destroy" do
    let(:work) do
      FactoryBot.valkyrie_create(:hyrax_resource, lease: lease)
    end
    let(:lease) { FactoryBot.create(:hyrax_lease) }

    before do
      work.visibility = public_vis
      Hyrax::AccessControlList(work).save
    end

    it "removes the lease" do
      actor.destroy

      expect(work.lease.lease_expiration_date).to eq nil
      expect(work.lease.visibility_after_lease).to eq nil
      expect(work.lease.visibility_during_lease).to eq nil
    end

    it "releases the lease" do
      expect { actor.destroy }
        .to change { Hyrax::LeaseManager.new(resource: work).under_lease? }
        .from(true)
        .to false
    end

    it "changes the visibility" do
      expect { actor.destroy }
        .to change { work.visibility }
        .from public_vis
    end

    context "with an expired lease" do
      let(:work) do
        FactoryBot.valkyrie_create(:hyrax_resource, lease: lease)
      end

      let(:lease) { FactoryBot.create(:hyrax_lease, :expired) }

      before do
        allow(Hyrax::TimeService)
          .to receive(:time_in_utc)
          .and_return(work.lease.lease_expiration_date.to_datetime + 1)
      end

      it "removes the lease" do
        actor.destroy

        expect(work.lease.lease_expiration_date).to eq nil
        expect(work.lease.visibility_after_lease).to eq nil
        expect(work.lease.visibility_during_lease).to eq nil
      end

      it "releases the lease" do
        expect { actor.destroy }
          .to change { Hyrax::LeaseManager.new(resource: work).enforced? }
          .from(true)
          .to false
      end

      it "changes the visibility" do
        expect { actor.destroy }
          .to change { work.visibility }
          .from(public_vis)
          .to authenticated_vis
      end
    end

    context "with a ActiveFedora model" do
      let(:work) do
        GenericWork.new do |work|
          work.apply_depositor_metadata 'foo'
          work.title = ["test"]
          work.visibility_during_lease = public_vis
          work.visibility_after_lease = private_vis
          work.lease_expiration_date = release_date.to_s
          work.save(validate: false)
        end
      end

      before do
        actor.destroy
      end

      context "with an active lease" do
        let(:release_date) { Time.zone.today + 2 }

        it "removes the lease" do
          expect(work.reload.lease_expiration_date).to be_nil
          expect(work.visibility).to eq public_vis
        end
      end

      context 'with an expired lease' do
        let(:release_date) { Time.zone.today - 2 }

        it "removes the lease" do
          expect(work.reload.lease_expiration_date).to be_nil
          expect(work.visibility).to eq private_vis
        end
      end
    end

    context 'deactivating an expired lease', clean_repo: true do
      let(:lease_attributes) do
        { lease_date: Date.tomorrow.to_s,
          current_state: public_vis,
          future_state: authenticated_vis }
      end
      let(:leased_work) { create(:leased_work, with_lease_attributes: lease_attributes) }
      let(:subject) { described_class.new(leased_work) }

      it 'destroys and reindexes the new permission appropriately in solr' do
        allow(leased_work.lease).to receive(:active?).and_return false
        subject.destroy
        expect(::SolrDocument.find(leased_work.id)[:visibility_ssi]).to eq(authenticated_vis)
      end
    end
  end
end
