# -*- encoding : utf-8 -*-
module Sufia
  module SolrDocumentBehavior
    extend ActiveSupport::Concern
    include Sufia::GenericFile::MimeTypes

    # Add a schema.org itemtype
    def itemtype
      Sufia.config.resource_types_to_schema[resource_type.first] || 'http://schema.org/CreativeWork'
    end

    def title_or_label
      title || label
    end

    ##
    # Give our SolrDocument an ActiveModel::Naming appropriate route_key
    def route_key
      get(Solrizer.solr_name('has_model', :symbol)).split(':').last.downcase
    end

    def to_param
      noid
    end

    ##
    # Offer the source (ActiveFedora-based) model to Rails for some of the
    # Rails methods (e.g. link_to).
    # @example
    #   link_to '...', SolrDocument(id: 'bXXXXXX5').new => <a href="/dams_object/bXXXXXX5">...</a>
    def to_model
      m = ActiveFedora::Base.load_instance_from_solr(id, self)
      return self if m.class == ActiveFedora::Base
      m
    end

    # Method to return the ActiveFedora model
    def hydra_model
      self[Solrizer.solr_name('active_fedora_model', Solrizer::Descriptor.new(:string, :stored, :indexed))]
    end

    def noid
      self[Solrizer.solr_name('noid', Sufia::GenericFile.noid_indexer)]
    end

    def date_uploaded
      field = self[Solrizer.solr_name("desc_metadata__date_uploaded", :stored_sortable, type: :date)]
      return unless field.present?
      begin
        Date.parse(field).to_formatted_s(:standard)
      rescue
        logger.info "Unable to parse date: #{field.first.inspect} for #{self['id']}"
      end
    end

    def depositor(default = '')
      val = Array(self[Solrizer.solr_name("depositor")]).first
      val.present? ? val : default
    end

    def title
      Array(self[Solrizer.solr_name('desc_metadata__title')]).first
    end

    def description
      Array(self[Solrizer.solr_name('desc_metadata__description')]).first
    end

    def label
      Array(self[Solrizer.solr_name('label')]).first
    end

    def file_format
       Array(self[Solrizer.solr_name('file_format')]).first
    end

    def creator
      Array(self[Solrizer.solr_name("desc_metadata__creator")]).first
    end

    def tags
      Array(self[Solrizer.solr_name("desc_metadata__tag")])
    end

    def resource_type
      Array(self[Solrizer.solr_name("desc_metadata__resource_type")])
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

    def public?
      read_groups.include?('public')
    end

    def registered?
      read_groups.include?('registered')
    end
  end
end
