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
# @example casting an ActiveFedora model to Valkyrie
#   work     = GenericWork.create(title: ['Comet in Moominland'])
#   resource = work.valkyrie_resource
#
#   resource.title # => ["Comet in Moominland"]
#   resource.title = ["Mumintrollet på kometjakt"]
#
#   Hyrax.persister.save(resource: resource)
#
#   work.reload
#   work.title # => ["Mumintrollet på kometjakt"]
#
# @example defining a native Valkyrie model for use with Wings
#   # given an `ActiveFodora` model like
#   class Book < ActiveFedora::Base
#     property :author, predicate: ::RDF::URI('http://example.com/ns/author')
#     property :title,  predicate: ::RDF::URI('http://example.com/ns/title')
#   end
#
#   # define a `Valkyrie` model with matching attributes,
#   class BookResource < Hyrax::Resource
#     attribute :author, Valkyrie::Types::String
#     attribute :title,  Valkyrie::Types::String
#   end
#
#   # and register the relationship with `Wings`
#   Wings::ModelRegistry.register(BookResource, Book)
#
#   # `Wings` will cast the `BookResource` to a `Book` to persist via `ActiveFedora`
#   resource = BookResource.new(author: 'Tove Jansson', title: 'Comet in Moominland')
#   adapter  = Wings::Valkyrie::MetadataAdapter.new
#   resource = adapter.persister.save(resource: resource)
#
#   resource.title  # => ["Comet in Moominland"]
#   resource.author # => ["Tove Jansson"]
#
#   resource.is_a?(BookResource) # => true
#
# @see https://wiki.duraspace.org/display/samvera/Hyrax-Valkyrie+Development+Working+Group
#      for further context regarding the approach
module Wings; end

require 'valkyrie'
require 'wings/indexing_configuration'
require 'wings/model_registry'
require 'wings/model_transformer'
require 'wings/orm_converter'
require 'wings/attribute_transformer'
require 'wings/services/custom_queries/find_access_control'
require 'wings/services/custom_queries/find_file_metadata'
require 'wings/services/custom_queries/find_many_by_alternate_ids'
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

# TODO: Custom query registration is not Wings specific.  These custom_queries need to be registered for other adapters too.
#       A refactor is needed to add the default implementations to hyrax.rb and only handle the wings specific overrides here.
custom_queries = [Hyrax::CustomQueries::Navigators::ChildCollectionsNavigator,
                  Hyrax::CustomQueries::Navigators::ChildFilesetsNavigator,
                  Hyrax::CustomQueries::Navigators::ChildWorksNavigator,
                  Hyrax::CustomQueries::Navigators::FindFiles,
                  Wings::CustomQueries::FindAccessControl, # override Hyrax::CustomQueries::FindAccessControl
                  Wings::CustomQueries::FindFileMetadata, # override Hyrax::CustomQueries::FindFileMetadata
                  Wings::CustomQueries::FindManyByAlternateIds] # override Hyrax::CustomQueries::FindManyByAlternateIds
custom_queries.each do |query_handler|
  Valkyrie.config.metadata_adapter.query_service.custom_queries.register_query_handler(query_handler)
end

Wings::ModelRegistry.register(Hyrax::AccessControl,     Hydra::AccessControl)
Wings::ModelRegistry.register(Hyrax::AdministrativeSet, AdminSet)
Wings::ModelRegistry.register(Hyrax::PcdmCollection,    '::Collection')
Wings::ModelRegistry.register(Hyrax::FileSet,           'FileSet')
Wings::ModelRegistry.register(Hyrax::Embargo,           Hydra::AccessControls::Embargo)
Wings::ModelRegistry.register(Hyrax::Lease,             Hydra::AccessControls::Lease)

Hydra::AccessControl.send(:define_method, :valkyrie_resource) do
  attrs = attributes.symbolize_keys
  attrs[:new_record]  = new_record?
  attrs[:created_at]  = create_date
  attrs[:updated_at]  = modified_date

  attrs[:permissions] = permissions.map do |permission|
    agent = permission.type == 'group' ? "group/#{permission.agent_name}" : permission.agent_name

    Hyrax::Permission.new(id: permission.id,
                          mode: permission.access.to_sym,
                          agent: agent,
                          access_to: Valkyrie::ID.new(permission.access_to_id),
                          new_record: permission.new_record?)
  end

  attrs[:access_to] = attrs[:permissions].find { |p| p.access_to&.id&.present? }&.access_to

  Hyrax::AccessControl.new(**attrs)
end
