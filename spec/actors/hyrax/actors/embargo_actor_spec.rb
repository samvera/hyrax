RSpec.describe Hyrax::Actors::EmbargoActor do
  let(:actor) { described_class.new(work) }
  let(:embargo) do
    create_for_repository(:embargo,
                          visibility_during_embargo: Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_AUTHENTICATED,
                          visibility_after_embargo: Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC,
                          embargo_release_date: [release_date])
  end
  let(:work) do
    create_for_repository(:work,
                          visibility: Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_AUTHENTICATED,
                          embargo_id: embargo.id)
  end

  describe "#destroy" do
    context "with an active embargo" do
      let(:release_date) { 2.days.from_now }

      it "removes the embargo" do
        actor.destroy
        reloaded = Hyrax::Queries.find_by(id: work.id)
        embargo_reloaded = Hyrax::Queries.find_by(id: reloaded.embargo_id)
        expect(embargo_reloaded.embargo_release_date).to be_nil
        expect(reloaded.visibility).to eq Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_AUTHENTICATED
      end
    end

    context 'with an expired embargo' do
      let(:release_date) { 2.days.ago }

      it "removes the embargo" do
        actor.destroy
        reloaded = Hyrax::Queries.find_by(id: work.id)
        embargo_reloaded = Hyrax::Queries.find_by(id: reloaded.embargo_id)
        expect(embargo_reloaded.embargo_release_date).to be_nil
        expect(reloaded.visibility).to eq Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC
      end
    end
  end
end
