# frozen_string_literal: true
require 'cancan/matchers'

RSpec.describe Hyrax::Ability::AdminSetAbility do
  subject(:ability) { ability_class.new(user) }
  let(:user) { FactoryBot.create(:user) }

  let(:ability_class) do
    module Hyrax
      module Test
        module AbilityMixin
          class Ability
            include CanCan::Ability
            include Hyrax::Ability::AdminSetAbility

            def initialize(user)
            end

            def admin?
              true
            end
          end
        end
      end
    end

    Hyrax::Test::AbilityMixin::Ability
  end

  after { Hyrax::Test.send(:remove_const, :AbilityMixin) }

  describe 'can?(:create)' do
    it 'allows create when local #admin? is true'
  end

  describe 'can?(:edit)' do
    it 'allows edit when local #admin? is true'
  end
end
