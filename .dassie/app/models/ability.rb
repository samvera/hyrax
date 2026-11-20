class Ability
  include Hydra::Ability
  
  include Hyrax::Ability
  include Bulkrax::AbilityBehavior
  self.ability_logic += [:everyone_can_create_curation_concerns]
  self.ability_logic += [:bulkrax_default_abilities]

  # Define any customized permissions here.
  def custom_permissions
    # Limits deleting objects to a the admin user
    #
    # if current_user.admin?
    #   can [:destroy], ActiveFedora::Base
    # end

    # Limits creating new objects to a specific group
    #
    # if user_groups.include? 'special_group'
    #   can [:create], ActiveFedora::Base
    # end

    if current_user.admin?
      can [:create, :show, :add_user, :remove_user, :index, :edit, :update, :destroy], Role
    end
  end

  def can_import_works?
    can_create_any_work?
  end

  def can_export_works?
    can_create_any_work?
  end

  def can_admin_importers?
    current_user.admin?
  end

  def can_admin_exporters?
    current_user.admin?
  end
end
