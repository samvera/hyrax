# frozen_string_literal: true
module Hyrax
  #
  # This class supports passing a user or providing a default user when the currently
  # logged in user is not available.  When adding the `user:` parameter to an existing
  # method, the `Hyrax::NullUser` can be used as a default value to maintain backward
  # compatibility. Whenever possible, calling methods should be updated to pass the
  # real user through from a place where the user was available.
  #
  # Example:
  # `Hyrax::Collections::NestedCollectionPersistenceService` methods use `Hyrax::NullUser.new`
  # as the default for the `user:` parameter. `Hyrax::Forms::Dashboard::NestCollectionForm #save`
  # method passes the current user to the service's `#persist_nested_collection_for` method.
  # All callers of all methods in this service in Hyrax code pass in the real user.  Use
  # of the `Hyrax::NullUser.new` provides backward compatibility for customizations.
  #
  class NullUser < ::User
    ##
    # @return [nil]
    def id
      '_NULL_USER_ID_'
    end

    ##
    # @return [nil]
    def user_key
      nil
    end
  end
end
