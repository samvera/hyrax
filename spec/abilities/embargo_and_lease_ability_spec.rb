require 'spec_helper'
require 'cancan/matchers'

describe "Ability on embargos and leases" do
  subject { Ability.new(current_user) }

  let(:current_user) { create(:user) }

  describe "a regular user" do
    it do
      is_expected.not_to be_able_to :index, Hydra::AccessControls::Embargo
      is_expected.not_to be_able_to :index, Hydra::AccessControls::Lease
    end
  end

  describe "an admin user" do
    before { allow(current_user).to receive(:groups).and_return(['admin']) }
    it do
      is_expected.to be_able_to :index, Hydra::AccessControls::Embargo
      is_expected.to be_able_to :index, Hydra::AccessControls::Lease
    end
  end
end
