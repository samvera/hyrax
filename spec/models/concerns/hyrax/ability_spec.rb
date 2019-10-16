require 'cancan/matchers'

RSpec.describe Hyrax::Ability, type: :model do
  subject(:ability) { ability_class.new(user) }
  let(:resource)    { FactoryBot.valkyrie_create(:hyrax_work) }
  let(:user)        { create(:user) }

  let(:ability_class) do
    Class.new do
      include Hydra::Ability
      include Hyrax::Ability
    end
  end

  context 'for valkyrie resources' do
    context 'when it is a private Work' do
      it { is_expected.not_to be_able_to(:read, resource) }
      it { is_expected.not_to be_able_to(:edit, resource) }
      it { is_expected.not_to be_able_to(:update, resource) }
      it { is_expected.not_to be_able_to(:destroy, resource) }
      it { is_expected.not_to be_able_to(:create, resource) }
    end

    context 'when it is a public Work' do
      let(:resource) { FactoryBot.valkyrie_create(:hyrax_work, :public) }
      it { is_expected.to be_able_to(:read, resource) }
    end
  end
end
