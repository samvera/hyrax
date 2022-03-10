# frozen_string_literal: true
module Hyrax
  module Transactions
    module Steps
      ##
      # A `dry-transcation` step that applies permission templates for a set of
      # collections on a given work.
      #
      # @since 3.0.0
      # @deprecated This is part of the legacy AF set of transaction steps for works.
      #   Transactions are not being used with AF works.  This will be removed in 4.0.
      class ApplyCollectionPermissionTemplate
        include Dry::Transaction::Operation

        ##
        # @param [Hyrax::WorkBehavior] work
        # @param [Array<#permision_template>] collections  a list of collections for which
        #   permission templates should be applied
        #
        # @return [Dry::Monads::Result]
        def call(work, collections: [])
          collections.each do |collection|
            template = Hyrax::PermissionTemplate.find_by!(source_id: collection.id)
            Hyrax::PermissionTemplateApplicator.apply(template).to(model: work)
          end

          Success(work)
        rescue ActiveRecord::RecordNotFound => err
          Failure(err)
        end
      end
    end
  end
end
