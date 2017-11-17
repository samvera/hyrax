RSpec.describe Hyrax::Actors::LeaseActor do
  let(:actor) { described_class.new(work) }

  # let(:work) do
  #   GenericWork.new do |work|
  #     work.apply_depositor_metadata 'foo'
  #     work.title = ["test"]
  #     work.visibility_during_lease = Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC
  #     work.visibility_after_lease = Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE
  #     work.lease_expiration_date = release_date.to_s
  #     work.save(validate: false)
  #   end
  # end
  let(:lease) do
    create_for_repository(:lease,
                          visibility_during_lease: Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC,
                          visibility_after_lease: Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE,
                          lease_expiration_date: [release_date])
  end
  let(:work) do
    create_for_repository(:work,
                          visibility: Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE,
                          lease_id: lease.id)
  end

  describe "#destroy" do
    before do
      actor.destroy
    end

    context "with an active lease" do
      let(:release_date) { 2.days.from_now }

      it "removes the lease" do
        reloaded = Hyrax::Queries.find_by(id: work.id)
        lease_reloaded = Hyrax::Queries.find_by(id: reloaded.lease_id)
        expect(lease_reloaded.lease_expiration_date).to be_nil
        expect(reloaded.visibility).to eq Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC
      end
    end

    context 'with an expired lease' do
      let(:release_date) { 2.days.ago }

      it "removes the lease" do
        reloaded = Hyrax::Queries.find_by(id: work.id)
        lease_reloaded = Hyrax::Queries.find_by(id: reloaded.lease_id)
        expect(lease_reloaded.lease_expiration_date).to be_nil
        expect(reloaded.visibility).to eq Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE
      end
    end
  end
end
