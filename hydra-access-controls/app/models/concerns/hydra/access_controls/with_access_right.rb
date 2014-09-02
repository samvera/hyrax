module Hydra
  module AccessControls
    module WithAccessRight
      extend ActiveSupport::Concern

      included do
        include Hydra::AccessControls::Permissions
      end

      delegate :open_access?, :open_access_with_embargo_release_date?, 
               :authenticated_only_access?, :private_access?, to: :access_rights

      protected
        def access_rights
          @access_rights ||= AccessRight.new(self)
        end

    end
  end
end
