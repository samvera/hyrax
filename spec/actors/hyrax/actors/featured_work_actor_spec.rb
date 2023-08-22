# frozen_string_literal: true
RSpec.describe Hyrax::Actors::FeaturedWorkActor, :active_fedora do
  let(:ability) { ::Ability.new(depositor) }
  let(:env) { Hyrax::Actors::Environment.new(work, ability, attributes) }
  let(:terminator) { Hyrax::Actors::Terminator.new }
  let(:depositor) { create(:user) }
  let(:work) { create(:work) }
  let(:attributes) { {} }
  let!(:feature) { FeaturedWork.create(work_id: work.id) }

  subject(:middleware) do
    stack = ActionDispatch::MiddlewareStack.new.tap do |middleware|
      middleware.use described_class
    end
    stack.build(terminator)
  end

  describe "#destroy" do
    it 'removes all the features' do
      expect { middleware.destroy(env) }.to change { FeaturedWork.where(work_id: work.id).count }.from(1).to(0)
    end
  end

  describe "#update" do
    context "of a public work" do
      let(:work) { create(:public_work) }

      it "does not modify the features" do
        expect { middleware.update(env) }.not_to change { FeaturedWork.where(work_id: work.id).count }
      end
    end

    context "of a private work" do
      it "removes the features" do
        expect { middleware.update(env) }.to change { FeaturedWork.where(work_id: work.id).count }.from(1).to(0)
      end
    end
  end
end
