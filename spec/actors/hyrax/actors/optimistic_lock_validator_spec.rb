# frozen_string_literal: true
RSpec.describe Hyrax::Actors::OptimisticLockValidator, :active_fedora do
  let(:env) { Hyrax::Actors::Environment.new(work, ability, attributes) }
  let(:ability) { ::Ability.new(depositor) }

  let(:terminator) { Hyrax::Actors::Terminator.new }
  let(:depositor) { create(:user) }
  let(:work) { create(:generic_work) }

  subject(:middleware) do
    stack = ActionDispatch::MiddlewareStack.new.tap do |middleware|
      middleware.use described_class
    end
    stack.build(terminator)
  end

  describe "update" do
    before do
      allow(terminator).to receive(:update).and_return(true)
    end

    subject { middleware.update(env) }

    context "when version is blank" do
      let(:attributes) { { version: '' } }

      it { is_expected.to be true }
    end

    context "when version is provided" do
      context "and the version is current" do
        let(:attributes) { { 'version' => work.etag } }

        it "returns true and calls the next actor without the version attribute" do
          expect(terminator).to receive(:update).with(Hyrax::Actors::Environment) do |k|
            expect(k.attributes).to eq({})
            true
          end
          expect(subject).to be true
        end
      end

      context "and the version is not current" do
        let(:attributes) { { 'version' => "W/\"ab2e8552cb5f7f00f91d2b223eca45849c722301\"" } }

        it "returns false and sets an error" do
          expect(subject).to be false
          expect(work.errors[:base]).to include "Your changes could not be saved because another " \
            "user (or background job) updated this Generic work after you began editing. Please " \
            "make sure all file attachments have completed successfully and try again. This form " \
            "has refreshed with the most recent saved copy of the Generic work."
        end
      end
    end
  end
end
