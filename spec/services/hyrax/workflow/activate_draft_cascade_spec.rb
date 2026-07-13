# frozen_string_literal: true
require 'hyrax/specs/shared_specs'

RSpec.describe Hyrax::Workflow::ActivateDraftCascade do
  subject(:workflow_method) { described_class }

  let(:user) { FactoryBot.create(:user) }
  let(:work) { FactoryBot.valkyrie_create(:hyrax_work) }

  it_behaves_like "a Hyrax workflow method"

  describe ".call" do
    context "when the draft_permission feature is disabled" do
      before { allow(Flipflop).to receive(:draft_permission?).and_return(false) }

      it "is a no-op that enqueues nothing" do
        expect { workflow_method.call(target: work, comment: nil, user: user) }
          .not_to have_enqueued_job(Hyrax::ActivateDraftCascadeJob)
      end

      it "returns true so the action still saves" do
        expect(workflow_method.call(target: work, comment: nil, user: user)).to eq true
      end
    end

    context "when the draft_permission feature is enabled" do
      before { allow(Flipflop).to receive(:draft_permission?).and_return(true) }

      it "applies the chosen target visibility to the root" do
        workflow_method.call(target: work, comment: nil, user: user, target_visibility: Hyrax::VisibilityIntention::PUBLIC)
        expect(work.visibility).to eq Hyrax::VisibilityIntention::PUBLIC
      end

      it "defaults to open visibility when none is supplied" do
        workflow_method.call(target: work, comment: nil, user: user)
        expect(work.visibility).to eq described_class::DEFAULT_VISIBILITY
      end

      it "enqueues the cascade job for the tree" do
        expect { workflow_method.call(target: work, comment: nil, user: user, target_visibility: 'open') }
          .to have_enqueued_job(Hyrax::ActivateDraftCascadeJob)
          .with(work.id.to_s, 'open')
      end

      it "returns truthy so ActionTakenService saves the target" do
        expect(workflow_method.call(target: work, comment: nil, user: user)).to be_truthy
      end
    end
  end
end
