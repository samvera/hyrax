# frozen_string_literal: true
require 'rails_helper'

RSpec.describe Hyrax::Actors::TransferRequestActor, :active_fedora do
  let(:ability) { ::Ability.new(depositor) }
  let(:env) { Hyrax::Actors::Environment.new(work, ability, attributes) }
  let(:terminator) { Hyrax::Actors::Terminator.new }
  let(:depositor) { create(:user) }
  let(:work) do
    build(:generic_work, on_behalf_of: proxied_to)
  end
  let(:attributes) { {} }

  subject(:middleware) do
    stack = ActionDispatch::MiddlewareStack.new.tap do |middleware|
      middleware.use described_class
    end
    stack.build(terminator)
  end

  describe "create" do
    context "when on_behalf_of is blank" do
      let(:proxied_to) { '' }

      it "returns true" do
        expect(middleware.create(env)).to be true
      end
    end

    context "when proxied_to is provided" do
      let(:proxied_to) { 'james@example.com' }

      before do
        create(:user, email: proxied_to)
        allow(terminator).to receive(:create).and_return(true)
      end

      it "adds the template users to the work" do
        expect(ChangeDepositorEventJob).to receive(:perform_later).with(work)
        expect(middleware.create(env)).to be true
      end
    end
  end
end
