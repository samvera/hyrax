require 'spec_helper'
require 'cancan/matchers'

describe 'User Abilities' do
  subject { ability }
  let(:ability) { Ability.new(current_user) }
  let(:user) { create(:user) }
  let(:current_user) { user }
  let(:admin_set) { create(:admin_set, edit_users: [user]) }

  it "allows the edit_users to edit and read" do
    is_expected.to be_able_to(:read, admin_set)
    is_expected.to be_able_to(:edit, admin_set)
  end
end
