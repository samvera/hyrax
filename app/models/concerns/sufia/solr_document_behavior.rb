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

    def to_param
      self[:id]
    end

    def title_or_label
      title || label
    end

    ##
    # Give our SolrDocument an ActiveModel::Naming appropriate route_key
    def route_key
      get(Solrizer.solr_name('has_model', :symbol)).split(':').last.downcase
    end

    ##
    # Offer the source (ActiveFedora-based) model to Rails for some of the
    # Rails methods (e.g. link_to).
    # @example
    #   link_to '...', SolrDocument(id: 'bXXXXXX5').new => <a href="/dams_object/bXXXXXX5">...</a>
    def to_model
      @m ||= ActiveFedora::Base.load_instance_from_solr(id)
      return self if @m.class == ActiveFedora::Base
      @m
    end

    # Method to return the ActiveFedora model
    def hydra_model
      self[Solrizer.solr_name('active_fedora_model', Solrizer::Descriptor.new(:string, :stored, :indexed))]
    end

    def date_uploaded
      field = self[Solrizer.solr_name("date_uploaded", :stored_sortable, type: :date)]
      return unless field.present?
      begin
        Date.parse(field).to_formatted_s(:standard)
      rescue
        ActiveFedora::Base.logger.info "Unable to parse date: #{field.first.inspect} for #{self['id']}"
      end
    end

    def depositor(default = '')
      val = Array(self[Solrizer.solr_name("depositor")]).first
      val.present? ? val : default
    end

    def title
      Array(self[Solrizer.solr_name('title')]).first
    end

    def description
      Array(self[Solrizer.solr_name('description')]).first
    end

    def label
      Array(self[Solrizer.solr_name('label')]).first
    end

    def file_format
      Array(self[Solrizer.solr_name('file_format')]).first
    end

    def creator
      Array(self[Solrizer.solr_name("creator")]).first
    end

    def tags
      Array(self[Solrizer.solr_name("tag")])
    end

    def resource_type
      Array(self[Solrizer.solr_name("resource_type")])
    end

    def mime_type
      Array(self[Solrizer.solr_name("mime_type")]).first
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

    def collection?
      hydra_model == 'Collection'
    end

    def generic_work?
      hydra_model == 'GenericWork'
    end
  end
end
