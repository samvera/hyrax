# frozen_string_literal: true
module Hyrax
  module Transactions
    module Steps
      ##
      # A `dry-transcation` step that applies a permission template
      # to a saved object.
      #
      # @note by design, this step should succeed even if for some reason a
      #   permission template could not be applied. it's better to complete the
      #   rest of the creation process with missing ACL grants than to crash and
      #   miss other crucial steps.
      #
      # @since 4.1.0
      class ApplyPermissionTemplate
        include Dry::Monads[:result]

        ##
        # @param [Hyrax::Work] object
        #
        # @return [Dry::Monads::Result]
        def call(object)
          template = Hyrax::PermissionTemplate.find_by(source_id: object&.admin_set_id)

          if template.blank?
            Hyrax.logger.info("At create time, #{object} doesn't have a " \
                              "PermissionTemplate, which it should have via " \
                              "AdministrativeSet #{object&.admin_set_id}). " \
                              "Continuing to create this object anyway.")

            return Success(object)
          end

          Hyrax::PermissionTemplateApplicator.apply(template).to(model: object) &&
            Success(object)
        end
      end
    end
  end
end
