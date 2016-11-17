require 'spec_helper'
require 'cancan/matchers'

describe "Ability on embargos and leases" do
  subject { Ability.new(current_user) }

  let(:current_user) { create(:user) }

  describe "a regular user" do
    it do
      should_not be_able_to :index, Hydra::AccessControls::Embargo
      should_not be_able_to :index, Hydra::AccessControls::Lease
    end
  end

  describe "an admin user" do
    before { allow(current_user).to receive(:groups).and_return(['admin']) }
    it do
      should be_able_to :index, Hydra::AccessControls::Embargo
      should be_able_to :index, Hydra::AccessControls::Lease
    end
  end
end
