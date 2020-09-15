# frozen_string_literal: true
module Hyrax
  module DashboardHelperBehavior
    def on_the_dashboard?
      params[:controller].match(%r{^hyrax/dashboard|hyrax/my})
    end

    # @param user [User]
    # @param where [Hash] applied as the where clause when querying the Hyrax::WorkRelation
    #
    # @see Hyrax::WorkRelation
    def number_of_works(user = current_user, where: { generic_type_sim: "Work" })
      where_clause = where.merge(DepositSearchBuilder.depositor_field => user.user_key)
      Hyrax::WorkRelation.new.where(where_clause).count
    rescue RSolr::Error::ConnectionRefused
      'n/a'
    end

    def number_of_files(user = current_user)
      ::FileSet.where(DepositSearchBuilder.depositor_field => user.user_key).count
    rescue RSolr::Error::ConnectionRefused
      'n/a'
    end

    def number_of_collections(user = current_user)
      ::Collection.where(DepositSearchBuilder.depositor_field => user.user_key).count
    rescue RSolr::Error::ConnectionRefused
      'n/a'
    end
  end
end
