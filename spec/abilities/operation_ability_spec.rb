require 'cancan/matchers'

RSpec.describe 'Abilities for Operations', type: :model do
  describe "a registered user" do
    subject { Ability.new(user) }

    let(:user) { create(:user) }

    it { is_expected.to be_able_to(:read, build(:operation, user: user)) }
    it { is_expected.not_to be_able_to(:read, build(:operation)) }
  end
end
