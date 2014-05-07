module Sufia
  module Ability
    extend ActiveSupport::Concern
    included do
      self.ability_logic += [:sufia_abilities]
    end

    def sufia_abilities
      generic_file_abilities
      featured_work_abilities
      editor_abilities
      stats_abilities
    end

    def featured_work_abilities
      can [:create, :destroy, :update], FeaturedWork if user_groups.include? 'admin'
    end

    def generic_file_abilities
      can :create, [GenericFile, Collection] if user_groups.include? 'registered'
    end

    def editor_abilities
      if user_groups.include? 'admin'
        can :create, TinymceAsset
        can :update, ContentBlock
      end
    end

    def stats_abilities
      alias_action :stats, to: :read
    end
  end
end
