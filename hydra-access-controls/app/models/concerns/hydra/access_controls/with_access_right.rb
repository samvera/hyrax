module Hydra
  module AccessControls
    module WithAccessRight
      extend ActiveSupport::Concern
      include Hydra::AccessControls::Permissions

      delegate :open_access?, :open_access_with_embargo_release_date?, 
               :authenticated_only_access?, :private_access?, to: :access_rights

      protected
        def access_rights
          @access_rights ||= AccessRight.new(self)
        end

    end
  end
end
