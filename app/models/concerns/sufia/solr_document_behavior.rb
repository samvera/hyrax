# -*- encoding : utf-8 -*-
module Sufia
  module SolrDocumentBehavior
    extend ActiveSupport::Concern
    include Hydra::Works::MimeTypes
    include Sufia::Permissions::Readable

    # Add a schema.org itemtype
    def itemtype
      Sufia.config.resource_types_to_schema[resource_type.first] || 'http://schema.org/CreativeWork'
    end

    ##
    # Give our SolrDocument an ActiveModel::Naming appropriate route_key
    def route_key
      get(Solrizer.solr_name('has_model', :symbol)).split(':').last.downcase
    end

    def date_created
      self[Solrizer.solr_name("date_created")]
    end

    # TODO: Move to curation_concerns?
    def identifier
      self[Solrizer.solr_name('identifier')]
    end

    # TODO: Move to curation_concerns?
    def based_near
      self[Solrizer.solr_name('based_near')]
    end

    # TODO: Move to curation_concerns?
    def related_url
      self[Solrizer.solr_name('related_url')]
    end

    # TODO: reconcile this with CurationConcerns (single vs multiple)
    def creator
      Array(self[Solrizer.solr_name("creator")]).first
    end

    # TODO: stop using this method and remove. Use `tags' instead.
    def tag
      tags
    end

    def resource_type
      Array(self[Solrizer.solr_name("resource_type")])
    end

    def read_groups
      Array(self[::Ability.read_group_field])
    end

    def edit_groups
      Array(self[::Ability.edit_group_field])
    end

    def edit_people
      Array(self[::Ability.edit_user_field])
    end

    def collection_ids
      Array(self['collection_ids_tesim'])
    end

    # Find the solr documents for the collections this object belongs to
    def collections
      return @collections if @collections
      query = 'id:' + collection_ids.map { |id| '"' + id + '"' }.join(' OR ')
      result = Blacklight.default_index.connection.select(params: { q: query })
      @collections = result['response']['docs'].map do |hash|
        SolrDocument.new(hash)
      end
    end

    def generic_work?
      hydra_model == 'GenericWork'
    end
  end
end
