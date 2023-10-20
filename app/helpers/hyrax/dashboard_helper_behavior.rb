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

    def link_to_works(user = current_user)
      state = Blacklight::SearchState.new(params, CatalogController.blacklight_config)
      facet_type = if Hyrax.config.use_valkyrie?
                     state.add_facet_params('generic_type_si', 'Work')
                   else
                     state.add_facet_params('generic_type_sim', 'Work')
                   end
      facet_depositor = state.add_facet_params('depositor_ssim', user.to_s)
      state = Hash.new {}
      state["f"] = facet_type["f"].merge(facet_depositor["f"])
      link_to(t("hyrax.dashboard.stats.works"), main_app.search_catalog_path(state))
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
