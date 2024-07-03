# frozen_string_literal: true
module Hyrax
  module Ability
    module FlexibleMetadataAbility
      def flexible_metadata_abilities
        can :manage, Hyrax::FlexibleSchema if admin? && Hyrax.config.flexible?
      end
    end
  end
end