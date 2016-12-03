require 'spec_helper'

describe Hyrax::Actors::LeaseActor do
  let(:actor) { described_class.new(work) }

  let(:work) do
    GenericWork.new do |work|
      work.apply_depositor_metadata 'foo'
      work.title = ["test"]
      work.visibility_during_lease = Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC
      work.visibility_after_lease = Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE
      work.lease_expiration_date = release_date.to_s
      work.save(validate: false)
    end
  end

  describe "#destroy" do
    before do
      actor.destroy
    end

    context "with an active lease" do
      let(:release_date) { Time.zone.today + 2 }

      it "removes the lease" do
        expect(work.reload.lease_expiration_date).to be_nil
        expect(work.visibility).to eq Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC
      end
    end

    context 'with an expired lease' do
      let(:release_date) { Time.zone.today - 2 }
      it "removes the lease" do
        expect(work.reload.lease_expiration_date).to be_nil
        expect(work.visibility).to eq Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE
      end
    end
  end
end
