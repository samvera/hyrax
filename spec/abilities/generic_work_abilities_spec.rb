# frozen_string_literal: true
require 'cancan/matchers'

RSpec.describe Hyrax::Ability, :active_fedora do
  subject { Ability.new(current_user) }

  let(:generic_work) { create(:private_generic_work, user: creating_user) }
  let(:user) { create(:user) }

  describe 'without embargo' do
    describe 'creator of object' do
      let(:creating_user) { user }
      let(:current_user) { user }

      it do
        is_expected.to be_able_to(:create, GenericWork.new)
        is_expected.to be_able_to(:read, generic_work)
        is_expected.to be_able_to(:update, generic_work)
        is_expected.to be_able_to(:destroy, generic_work)
      end
    end

    describe 'as a repository manager' do
      let(:manager_user) { create(:admin) }
      let(:creating_user) { user }
      let(:current_user) { manager_user }

      it do
        is_expected.to be_able_to(:create, GenericWork.new)
        is_expected.to be_able_to(:read, generic_work)
        is_expected.to be_able_to(:update, generic_work)
        is_expected.to be_able_to(:destroy, generic_work)
      end
    end

    describe 'another authenticated user' do
      let(:creating_user) { create(:user) }
      let(:current_user) { user }

      it do
        is_expected.to be_able_to(:create, GenericWork.new)
        is_expected.not_to be_able_to(:read, generic_work)
        is_expected.not_to be_able_to(:update, generic_work)
        is_expected.not_to be_able_to(:destroy, generic_work)
        is_expected.to be_able_to(:collect, generic_work)
      end
    end

    describe 'a nil user' do
      let(:creating_user) { create(:user) }
      let(:current_user) { nil }

      it do
        is_expected.not_to be_able_to(:create, GenericWork.new)
        is_expected.not_to be_able_to(:read, generic_work)
        is_expected.not_to be_able_to(:update, generic_work)
        is_expected.not_to be_able_to(:destroy, generic_work)
        is_expected.not_to be_able_to(:collect, generic_work)
      end
    end
  end
end
