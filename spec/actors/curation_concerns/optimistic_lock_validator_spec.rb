require 'spec_helper'

RSpec.describe CurationConcerns::OptimisticLockValidator do
  let(:update_actor) do
    double('update actor', update: true,
                           curation_concern: work,
                           user: depositor)
  end

  let(:actor) do
    CurationConcerns::Actors::ActorStack.new(work, depositor, [described_class])
  end

  let(:depositor) { create(:user) }
  let(:work) { create(:generic_work) }

  describe "update" do
    before do
      allow(CurationConcerns::Actors::RootActor).to receive(:new).and_return(update_actor)
      allow(update_actor).to receive(:update).and_return(true)
    end

    subject { actor.update(attributes) }

    context "when version is blank" do
      let(:attributes) { { version: '' } }
      it { is_expected.to be true }
    end

    context "when version is provided" do
      context "and the version is current" do
        let(:attributes) { { version: work.etag } }

        it "returns true and calls the next actor without the version attribute" do
          expect(update_actor).to receive(:update).with({}).and_return(true)
          expect(subject).to be true
        end
      end

      context "and the version is not current" do
        let(:attributes) { { version: "W/\"ab2e8552cb5f7f00f91d2b223eca45849c722301\"" } }

        it "returns false and sets an error" do
          expect(subject).to be false
          expect(work.errors[:base]).to include "Another user has made a change to that Generic work since you accessed the edit form."
        end
      end
    end
  end
end
