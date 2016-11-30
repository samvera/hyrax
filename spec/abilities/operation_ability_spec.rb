require 'spec_helper'
require 'cancan/matchers'

describe 'Abilities for Operations', type: :model do
  describe "a registered user" do
    let(:user) { create(:user) }
    subject { Ability.new(user) }
    it { is_expected.to be_able_to(:read, build(:operation, user: user)) }
    it { is_expected.not_to be_able_to(:read, build(:operation)) }
  end
end
