# frozen_string_literal: true
module Hyrax
  module DashboardHelperBehavior
    def on_the_dashboard?
      params[:controller].match(%r{^hyrax/dashboard|hyrax/my})
    end

    # @param user [User]
    # @return [Integer] number of works that the user deposited
    def number_of_works(user = current_user)
      Hyrax::SolrQueryService
        .new
        .with_field_pairs(field_pairs: field_pairs(user))
        .with_generic_type(generic_type: 'Work')
        .count
    rescue RSolr::Error::ConnectionRefused
      'n/a'
    end

    # @param user [User]
    # @return [Integer] number of FileSets the user deposited
    def number_of_files(user = current_user)
      Hyrax::SolrQueryService
        .new
        .with_field_pairs(field_pairs: field_pairs(user))
        .with_generic_type(generic_type: 'FileSet')
        .count
    rescue RSolr::Error::ConnectionRefused
      'n/a'
    end

    # @param user [User]
    # @return [Integer] number of Collections the user created
    def number_of_collections(user = current_user)
      Hyrax::SolrQueryService
        .new
        .with_field_pairs(field_pairs: field_pairs(user))
        .with_generic_type(generic_type: 'Collection')
        .count
    rescue RSolr::Error::ConnectionRefused
      'n/a'
    end

    private

    def field_pairs(user)
      { DepositSearchBuilder.depositor_field => user.user_key }
    end
  end
end
