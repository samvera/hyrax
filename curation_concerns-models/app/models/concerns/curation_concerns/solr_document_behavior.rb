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
      fetch(Solrizer.solr_name('hasRelatedMediaFragment', :symbol), []).first
    end

    # Date created is indexed as a string. This allows users to enter values like: 'Circa 1840-1844'
    def date_created
      fetch(Solrizer.solr_name("date_created"), []).first
    end

    def date_modified
      date_field('date_modified')
    end

    def date_uploaded
      date_field('date_uploaded')
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
      fetch(Solrizer.solr_name('creator'), [])
    end

    def contributor
      fetch(Solrizer.solr_name('contributor'), [])
    end

    def subject
      fetch(Solrizer.solr_name('subject'), [])
    end

    def publisher
      fetch(Solrizer.solr_name('publisher'), [])
    end

    def language
      fetch(Solrizer.solr_name('language'), [])
    end

    def tags
      fetch(Solrizer.solr_name('tag'), [])
    end

    def embargo_release_date
      self[Hydra.config.permissions.embargo.release_date]
    end

    def lease_expiration_date
      self[Hydra.config.permissions.lease.expiration_date]
    end

    def rights
      self[Solrizer.solr_name('rights')]
    end

    def mime_type
      self[Solrizer.solr_name('mime_type', :stored_sortable)]
    end

    def read_groups
      fetch(Hydra.config.permissions.read.group, [])
    end

    def visibility
      @visibility ||= if read_groups.include? Hydra::AccessControls::AccessRight::PERMISSION_TEXT_VALUE_PUBLIC
                        Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC
                      elsif read_groups.include? Hydra::AccessControls::AccessRight::PERMISSION_TEXT_VALUE_AUTHENTICATED
                        Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_AUTHENTICATED
                      else
                        Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE
                      end
    end

    private

      def date_field(field_name)
        field = self[Solrizer.solr_name(field_name, :stored_sortable, type: :date)]
        return unless field.present?
        begin
          Date.parse(field).to_formatted_s(:standard)
        rescue
          Rails.logger.info "Unable to parse date: #{field.first.inspect} for #{self['id']}"
        end
      end
  end
end
