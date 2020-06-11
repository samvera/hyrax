# frozen_string_literal: true
require 'cancan/matchers'

RSpec.describe Hyrax::Ability do
  describe "a registered user" do
    subject { Ability.new(user) }

    let(:user) { create(:user) }

    it { is_expected.to be_able_to(:read, build(:operation, user: user)) }
    it { is_expected.not_to be_able_to(:read, build(:operation)) }
  end
end
