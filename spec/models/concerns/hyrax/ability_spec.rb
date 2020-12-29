# frozen_string_literal: true
require 'cancan/matchers'

RSpec.describe Hyrax::Ability do
  subject(:ability) { ability_class.new(user) }
  let(:user) { FactoryBot.create(:user) }

  shared_context 'with guest user' do
    let(:user) { FactoryBot.create(:user, :guest) }
  end

  shared_context 'with deposit access on an admin set' do
    let(:permission_template) { FactoryBot.create(:permission_template, with_admin_set: true) }

    before do
      FactoryBot.create(:permission_template_access,
                        :deposit,
                        permission_template: permission_template,
                        agent_type: 'user',
                        agent_id: user.user_key)
    end
  end

  shared_context 'with create access on a work type' do
    let(:work_model) { Monograph }

    before { ability.can(:create, work_model) }
  end

  let(:ability_class) do
    module Hyrax
      module Test
        module AbilityMixin
          class Ability
            include Blacklight::AccessControls::Ability
            include Hyrax::Ability
          end
        end
      end
    end
  end

  after { Hyrax::Test.send(:remove_const, :AbilityMixin) }

  describe '#can_create_any_work?' do
    its(:can_create_any_work?) { is_expected.to be false }

    context 'when user can deposit to an admin set' do
      include_context 'with deposit access on an admin set'

      its(:can_create_any_work?) { is_expected.to be false }

      context 'and user can create a work type' do
        include_context 'with create access on a work type'

        its(:can_create_any_work?) { is_expected.to be true }
      end
    end
  end

  describe '#registered_user?' do
    context 'with a guest user' do
      include_context 'with guest user'

      its(:registered_user?) { is_expected.to be false }
    end
  end
end
