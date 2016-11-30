require 'spec_helper'
require 'cancan/matchers'

describe CurationConcerns::Ability, type: :model do
  context "with a registered user" do
    let(:user) { create(:user) }
    subject { Ability.new(user) }
    it { is_expected.not_to be_able_to(:read, :admin_dashboard) }
  end
  context "with an administrative user" do
    let(:user) { create(:admin) }
    subject { Ability.new(user) }
    it { is_expected.to be_able_to(:read, :admin_dashboard) }
  end
end
