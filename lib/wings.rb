# frozen_string_literal: true

##
# Wings is a toolkit integrating Valkyrie into Hyrax as a bridge away from the
# hard dependency on ActiveFedora.
#
# Requiring this module with `require 'wings'` injects a variety of behavior
# supporting a gradual transition from existing `ActiveFedora` models and
# persistence middleware to Valkyrie.
#
# `Wings` is primarily an isolating namespace for code intended to be removed
# after a full transition to `Valkyrie` as the persistence middleware for Hyrax.
# Applications may find it useful to depend directly on this code to facilitate
# a smooth code migration, much in the way it is being used in this engine.
# However, these dependencies should be considered temprorary: this code will
# be deprecated for removal in a future release.
#
# @see https://wiki.duraspace.org/display/samvera/Hyrax-Valkyrie+Development+Working+Group
#      for further context regarding the approach
module Wings; end

require 'valkyrie'
require 'wings/model_transformer'
require 'wings/valkyrizable'
require 'wings/valkyrie/metadata_adapter'
require 'wings/valkyrie/resource_factory'
require 'wings/valkyrie/persister'
require 'wings/valkyrie/query_service'
require 'wings/valkyrie/storage/active_fedora'

ActiveFedora::Base.include Wings::Valkyrizable

Valkyrie::MetadataAdapter.register(
  Wings::Valkyrie::MetadataAdapter.new, :wings_adapter
)
Valkyrie.config.metadata_adapter = :wings_adapter

Valkyrie::StorageAdapter.register(
  Wings::Storage::ActiveFedora
    .new(connection: Ldp::Client.new(ActiveFedora.fedora.host), base_path: ActiveFedora.fedora.base_path),
  :active_fedora
)
Valkyrie.config.storage_adapter = :active_fedora

[Hyrax::CustomQueries::Wings,
 Hyrax::CustomQueries::Navigators::ChildCollectionsNavigator,
 Hyrax::CustomQueries::Navigators::ChildFilesetsNavigator,
 Hyrax::CustomQueries::Navigators::ChildWorksNavigator,
 Hyrax::CustomQueries::FindAccessControl].each do |query_handler|
  Valkyrie.config.metadata_adapter.query_service.custom_queries.register_query_handler(query_handler)
end

Hydra::AccessControl.define_method(:valkyrie_resource) do
  attrs = attributes.symbolize_keys
  attrs[:new_record]  = new_record?
  attrs[:created_at]  = create_date
  attrs[:updated_at]  = modified_date

  attrs[:permissions] = permissions.map do |permission|
    Hyrax::Permission.new(id: permission.id,
                          mode: permission.access.to_sym,
                          agent: permission.agent_name,
                          access_to: Valkyrie::ID.new(permission.access_to_id),
                          new_record: permission.new_record?)
  end

  attrs[:access_to] = attrs[:permissions].find { |p| p.access_to&.id&.present? }&.access_to

  Hyrax::AccessControl.new(**attrs)
end
