# will move to lib/hydra/access_control folder/namespace in release 5.x
# Provides methods for determining permissions
# If you include this into a Controller, it will also make a number of these methods available as view helpers.
module Hydra::AccessControlsEvaluation
  
  def self.included(klass)
    if klass.respond_to?(:helper_method)
      klass.helper_method(:editor?)
      klass.helper_method(:reader?)
      klass.helper_method(:test_permission?)
    end
  end
  
  # Test the current user's permissions.  This method is used by the editor? and reader? methods
  # @param [Symbol] permission_type valid options: :edit, :read
  # This is available as a view helper method as well as within your controllers.
  # @example
  #   test_permission(:edit)
  def test_permission(permission_type)    
    ActiveSupport::Deprecation.warn("test_permission has been deprecated. Use can? instead") 
    can? permission_type, @permissions_solr_document
  end

  # Test whether the the current user has edit permissions.  
  # This is available as a view helper method as well as within your controllers.
  def editor?
    logger.warn("editor? has been deprecated. Use can? instead")
    can? :edit, @permissions_solr_document
  end
  
  # Test whether the the current user has read permissions.  
  # This is available as a view helper method as well as within your controllers.
  def reader?
    logger.warn("reader? has been deprecated. Use can? instead")
    can? :read, @permissions_solr_document
  end

end
