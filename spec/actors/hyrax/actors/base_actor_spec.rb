RSpec.describe Hyrax::Actors::BaseActor do
  let(:ability) { ::Ability.new(user) }
  let(:attributes) { {} }
  let(:env) { Hyrax::Actors::Environment.new(work, ability, attributes) }
  let(:terminator) { Hyrax::Actors::Terminator.new }
  let(:user) { create(:user) }
  let(:work) { create(:work) }

  subject(:middleware) do
    stack = ActionDispatch::MiddlewareStack.new.tap do |middleware|
      middleware.use described_class
    end
    stack.build(terminator)
  end

  describe "#create" do
    let(:work) { FactoryBot.build(:work) }
    it 'persists the work' do
      expect { middleware.create(env) }
        .to change { work.persisted? }
        .to true
    end
  end

  describe "#update" do
    it 'updates a work' do
      expect(middleware.update(env)).to be true
    end
  end

  describe "#destroy" do
    it 'deletes a work' do
      expect(middleware.destroy(env)).to be true
    end
  end
end
