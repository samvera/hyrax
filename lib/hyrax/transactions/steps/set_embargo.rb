# frozen_string_literal: true
require 'dry/monads'

module Hyrax
  module Transactions
    module Steps
      ##
      # Adds and removes work members
      class SetEmbargo
        include Dry::Monads[:result]

        ##
        # @param [Hyrax::Work] obj
        # @param [Hash] work_members_attributes
        #
        # @return [Dry::Monads::Result]
        def call(work_resource, embargo_set: nil, end_date: nil, visibility_after_embargo: nil, visibility_during_embargo: nil)
          return Success(work_resource) unless embargo_set.eql?("embargo")

          # I'm not quite sure what to do here.  I think it may be something like this.
          embargo = Hyrax::Embargo.new(visibility_during_embargo: visibility_during_embargo,
                                       visibility_after_embargo: visibility_after_embargo,
                                       embargo_release_date: end_date)

          resource            = Hyrax::Resource.new(embargo: embargo)
          resource.visibility = 'open'

          manager = EmbargoManager.new(resource: work_resource)

          manager.apply!
          manager.enforced? # => true
          resource.visibility # => 'restricted'
\

          Success(work_resource)
        end
      end
    end
  end
end
