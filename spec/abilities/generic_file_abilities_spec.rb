require 'spec_helper'
require 'cancan/matchers'

describe 'User' do
  describe 'Abilities' do
    subject { ability }
    let(:ability) { Ability.new(current_user) }
    let(:visibility) { Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE }
    let(:creating_user) { FactoryGirl.create(:user) }
    let(:user) { FactoryGirl.create(:user) }
    let(:current_user) { user }
    let(:generic_work) {  FactoryGirl.create(:generic_work, visibility: visibility, user: creating_user) }
    let(:generic_file) {  FactoryGirl.create(:generic_file, visibility: visibility, user: creating_user) }

    describe 'without embargo' do
      describe 'creator of object' do
        let(:creating_user) { user }
        let(:current_user) { user }
        it do
          should be_able_to(:create, GenericFile.new)
          should be_able_to(:read, generic_file)
          should be_able_to(:update, generic_file)
          should_not be_able_to(:delete, generic_file)
        end
      end

      describe 'as a repository manager' do
        let(:manager_user) { FactoryGirl.create(:admin) }
        let(:creating_user) { user }
        let(:current_user) { manager_user }
        it do
          should be_able_to(:create, ::GenericFile.new)
          should be_able_to(:read, generic_file)
          should be_able_to(:update, generic_file)
          should be_able_to(:destroy, generic_file)
        end
      end

      describe 'another authenticated user' do
        let(:creating_user) { FactoryGirl.create(:user) }
        let(:current_user) { user }
        it do
          should be_able_to(:create, ::GenericFile.new)
          should_not be_able_to(:read, generic_file)
          should_not be_able_to(:update, generic_file)
          should_not be_able_to(:delete, generic_file)
        end
      end

      describe 'a nil user' do
        let(:creating_user) { FactoryGirl.create(:user) }
        let(:current_user) { nil }
        it do
          should_not be_able_to(:create, GenericFile.new)
          should_not be_able_to(:read, generic_file)
          should_not be_able_to(:update, generic_file)
          should_not be_able_to(:delete, generic_file)
        end
      end
    end
  end
end
