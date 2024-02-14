# frozen_string_literal: true
##
# The default Blacklight catalog `search_builder_class` for Hyrax.
#
# Use of this builder is configured in the `CatalogController` generated by
# Hyrax's install task.
#
# If you plan to customize the base catalog search builder behavior (e.g. by
# adding a mixin module provided by a blacklight extension gem), inheriting this
#  class, customizing behavior, and reconfiguring `CatalogController` is the
# preferred mechanism.
#
# @example extending and customizing SearchBuilder
#   class MyApp::CustomCatalogSearchBuilder < Hyrax::CatalogSearchBuilder
#     include BlacklightRangeLimit::RangeLimitBuilder
#     # and/or other extensions
#   end
#
#   class CatalogController < ApplicationController
#     # ...
#     configure_blacklight do |config|
#       config.search_builder_class = MyApp::CustomCatalogSearchBuilder
#     # ...
#     end
#     # ...
#   end
#
# @see Blacklight::SearchBuilder
# @see Hyrax::SearchFilters
class Hyrax::CatalogSearchBuilder < Hyrax::SearchBuilder
  self.default_processor_chain += [
    :add_access_controls_to_solr_params,
    :show_works_or_works_that_contain_files,
    :show_only_active_records,
    :filter_collection_facet_for_access
  ]

  # show both works that match the query and works that contain files that match the query
  def show_works_or_works_that_contain_files(solr_parameters)
    return if blacklight_params[:q].blank? || blacklight_params[:search_field] != 'all_fields'
    solr_parameters[:user_query] = blacklight_params[:q]
    solr_parameters[:q] = new_query
    solr_parameters[:defType] = 'lucene'
  end

  # show works that are in the active state.
  def show_only_active_records(solr_parameters)
    solr_parameters[:fq] ||= []
    solr_parameters[:fq] << '-suppressed_bsi:true'
  end

  # only return facet counts for collections that this user has access to see
  def filter_collection_facet_for_access(solr_parameters)
    return if current_ability.admin?

    collection_ids = Hyrax::Collections::PermissionsService.collection_ids_for_view(ability: current_ability).map { |id| "^#{id}$" }
    solr_parameters['f.member_of_collection_ids_ssim.facet.matches'] = if collection_ids.present?
                                                                         collection_ids.join('|')
                                                                       else
                                                                         "^$"
                                                                       end
  end

  private

  # the {!lucene} gives us the OR syntax
  def new_query
    "{!lucene}#{interal_query(dismax_query)} #{interal_query(join_for_works_from_files)}"
  end

  # the _query_ allows for another parser (aka dismax)
  def interal_query(query_value)
    "_query_:\"#{query_value}\""
  end

  # the {!dismax} causes the query to go against the query fields
  def dismax_query
    "{!dismax v=$user_query}"
  end

  # join from file id to work relationship solrized member_ids_ssim
  def join_for_works_from_files
    "{!join from=#{Hyrax.config.id_field} to=member_ids_ssim v=has_model_ssim:*FileSet}#{dismax_query}"
  end
end
