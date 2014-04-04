module Sufia
  module Ability
    extend ActiveSupport::Concern
    included do
      self.ability_logic += [:sufia_abilities]
    end

    def sufia_abilities
      generic_file_abilities
      editor_abilities
    end

    def generic_file_abilities
      can :create, GenericFile if user_groups.include? 'registered'
    end

    def editor_abilities
      if user_groups.include? 'admin'
        can :create, TinymceAsset
        can :update, ContentBlock
      end
    end
  end
end
