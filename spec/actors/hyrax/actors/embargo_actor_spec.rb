# frozen_string_literal: true
RSpec.describe Hyrax::Actors::EmbargoActor do
  let(:actor) { described_class.new(work) }

  let(:work) do
    GenericWork.new do |work|
      work.apply_depositor_metadata 'foo'
      work.title = ["test"]
      work.visibility = Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_AUTHENTICATED
      work.visibility_during_embargo = Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_AUTHENTICATED
      work.visibility_after_embargo = Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC
      work.embargo_release_date = release_date.to_s
      work.save(validate: false)
    end
  end

  describe "#destroy" do
    context "with an active embargo" do
      let(:release_date) { Time.zone.today + 2 }

      it "removes the embargo" do
        actor.destroy
        expect(work.reload.embargo_release_date).to be_nil
        expect(work.visibility).to eq Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_AUTHENTICATED
      end
    end

    context 'with an expired embargo' do
      let(:release_date) { Time.zone.today - 2 }

      it "removes the embargo" do
        actor.destroy
        expect(work.reload.embargo_release_date).to be_nil
        expect(work.visibility).to eq Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC
      end
    end
  end
end
