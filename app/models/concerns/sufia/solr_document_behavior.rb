# -*- encoding : utf-8 -*-
module Sufia
  module SolrDocumentBehavior
    extend ActiveSupport::Concern
    include Hydra::Works::MimeTypes
    include CurationConcerns::Permissions::Readable
    include Sufia::SolrDocument::Export
    include Sufia::SolrDocument::Characterization

    # Add a schema.org itemtype
    def itemtype
      ResourceTypesService.microdata_type(resource_type.first)
    end

    # Date created indexed as a string. This allows users to enter values like: 'Circa 1840-1844'
    # This overrides the default behavior of CurationConcerns which indexes a date
    def date_created
      fetch(Solrizer.solr_name("date_created"), [])
    end

    def create_date
      date_field('system_create')
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

    def resource_type
      Array.wrap(self[Solrizer.solr_name("resource_type")])
    end

    def read_groups
      Array.wrap(self[::Ability.read_group_field])
    end

    def edit_groups
      Array.wrap(self[::Ability.edit_group_field])
    end

    def edit_people
      Array.wrap(self[::Ability.edit_user_field])
    end

    def collection_ids
      Array.wrap(self['collection_ids_tesim'])
    end

    # Find the solr documents for the collections this object belongs to
    def collections
      return @collections if @collections
      query = 'id:' + collection_ids.map { |id| '"' + id + '"' }.join(' OR ')
      result = Blacklight.default_index.connection.select(params: { q: query })
      @collections = result['response']['docs'].map do |hash|
        ::SolrDocument.new(hash)
      end
    end
  end
end
