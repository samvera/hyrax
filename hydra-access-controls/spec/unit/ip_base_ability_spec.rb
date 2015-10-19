require 'spec_helper'

describe Hydra::IpBasedAbility do
  before do
    class TestAbility < Ability
      include Hydra::IpBasedAbility
    end
  end

  let(:user) { double(groups: ['one', 'two'], new_record?: false) }
  let(:ability) { TestAbility.new(user, args) }
  let(:args) { {} }

  describe "#user_groups" do
    subject { ability.user_groups }
    context "when no ip is passed" do
      it { is_expected.to eq ['public', 'one', 'two', 'registered'] }
    end

    context "when ip is passed" do
      context "and it is in range" do
        let(:args) { { remote_ip: '10.0.1.12' } }
        it { is_expected.to eq ['public', 'one', 'two', 'registered', 'on-campus'] }
      end

      context "and it is out of range" do
        let(:args) { { remote_ip: '10.0.4.12' } }
        it { is_expected.to eq ['public', 'one', 'two', 'registered'] }
      end
    end
  end
end
