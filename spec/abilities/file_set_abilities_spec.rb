# frozen_string_literal: true
require 'cancan/matchers'

RSpec.describe Hyrax::Ability do
  subject(:ability) { Ability.new(current_user) }
  let(:visibility) { Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE }
  let(:creating_user) { create(:user) }
  let(:user) { create(:user) }
  let(:current_user) { user }
  let(:generic_work) { valkyrie_create(:hyrax_work, visibility_setting: visibility, edit_users: [creating_user]) }
  let(:file_set) { valkyrie_create(:hyrax_file_set, visibility_setting: visibility, edit_users: [creating_user]) }

  describe 'without embargo' do
    describe 'creator of object' do
      let(:creating_user) { user }
      let(:current_user) { user }

      it do
        is_expected.to be_able_to(:create, FileSet.new)
        is_expected.to be_able_to(:versions, file_set)
        is_expected.to be_able_to(:read, file_set)
        is_expected.to be_able_to(:update, file_set)
        is_expected.not_to be_able_to(:delete, file_set)
      end
    end

    describe 'as a repository manager' do
      let(:manager_user) { create(:admin) }
      let(:creating_user) { user }
      let(:current_user) { manager_user }

      it do
        is_expected.to be_able_to(:create, FileSet.new)
        is_expected.to be_able_to(:versions, file_set)
        is_expected.to be_able_to(:read, file_set)
        is_expected.to be_able_to(:update, file_set)
        is_expected.to be_able_to(:destroy, file_set)
      end
    end

    describe 'another authenticated user' do
      let(:creating_user) { create(:user) }
      let(:current_user) { user }

      it do
        is_expected.to be_able_to(:create, FileSet.new)
        is_expected.not_to be_able_to(:versions, file_set)
        is_expected.not_to be_able_to(:read, file_set)
        is_expected.not_to be_able_to(:update, file_set)
        is_expected.not_to be_able_to(:delete, file_set)
      end
    end

    describe 'a nil user' do
      let(:creating_user) { create(:user) }
      let(:current_user) { nil }

      it do
        is_expected.not_to be_able_to(:create, FileSet.new)
        is_expected.not_to be_able_to(:versions, file_set)
        is_expected.not_to be_able_to(:read, file_set)
        is_expected.not_to be_able_to(:update, file_set)
        is_expected.not_to be_able_to(:delete, file_set)
      end
    end
  end
end
