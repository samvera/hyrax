module CurationConcerns
  module SolrDocumentBehavior
    extend ActiveSupport::Concern
    include Hydra::Works::MimeTypes

    def title_or_label
      title || label
    end

    def to_param
      id
    end

    def to_s
      title_or_label
    end

    ##
    # Offer the source (ActiveFedora-based) model to Rails for some of the
    # Rails methods (e.g. link_to).
    # @example
    #   link_to '...', SolrDocument(:id => 'bXXXXXX5').new => <a href="/dams_object/bXXXXXX5">...</a>
    def to_model
      @model ||= begin
        m = ActiveFedora::Base.load_instance_from_solr(id, self)
        m.class == ActiveFedora::Base ? self : m
      end
    end

    def collection?
      hydra_model == 'Collection'
    end

    # Method to return the ActiveFedora model
    def hydra_model
      self[Solrizer.solr_name('active_fedora_model', Solrizer::Descriptor.new(:string, :stored, :indexed))]
    end

    def human_readable_type
      Array(self[Solrizer.solr_name('human_readable_type', :stored_searchable)]).first
    end

    def representative_id
      Array(self[Solrizer.solr_name('representative', :symbol)]).first
    end

    def date_uploaded
      field = self[Solrizer.solr_name('date_uploaded', :stored_sortable, type: :date)]
      return unless field.present?
      begin
        Date.parse(field).to_formatted_s(:standard)
      rescue
        Rails.logger.info "Unable to parse date: #{field.first.inspect} for #{self['id']}"
      end
    end

    def depositor(default = '')
      val = Array(self[Solrizer.solr_name('depositor')]).first
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
      Array(self[Solrizer.solr_name('creator')]).first
    end

    def contributor
      Array(self[Solrizer.solr_name('contributor')]).first
    end

    def subject
      Array(self[Solrizer.solr_name('subject')]).first
    end

    def publisher
      Array(self[Solrizer.solr_name('publisher')]).first
    end

    def language
      Array(self[Solrizer.solr_name('language')]).first
    end

    def tags
      Array(self[Solrizer.solr_name('tag')])
    end

    def embargo_release_date
      self['embargo_release_date_dtsi']
    end

    def lease_expiration_date
      self['lease_expiration_date_dtsi']
    end

    def rights
      self[Solrizer.solr_name('rights')]
    end

    def mime_type
      self[Solrizer.solr_name('mime_type', :stored_sortable)]
    end

    def read_groups
      fetch('read_access_group_ssim', [])
    end

    def visibility
      if read_groups.include? Hydra::AccessControls::AccessRight::PERMISSION_TEXT_VALUE_PUBLIC
        Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC
      elsif read_groups.include? Hydra::AccessControls::AccessRight::PERMISSION_TEXT_VALUE_AUTHENTICATED
        Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_AUTHENTICATED
      else
        Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE
      end
    end
  end
end
