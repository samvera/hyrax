# -*- encoding : utf-8 -*-
module Hyrax
  module SolrDocumentBehavior
    extend ActiveSupport::Concern
    include Hydra::Works::MimeTypes
    include Hyrax::Permissions::Readable
    include Hyrax::SolrDocument::Export
    include Hyrax::SolrDocument::Characterization

    # Add a schema.org itemtype
    def itemtype
      ResourceTypesService.microdata_type(resource_type.first)
    end

    def title_or_label
      return label if title.blank?
      title.join(', ')
    end

    def to_param
      id
    end

    def to_s
      title_or_label
    end

    class ModelWrapper
      def initialize(model, id)
        @model = model
        @id = id
      end

      def persisted?
        true
      end

      def to_param
        @id
      end

      def model_name
        @model.model_name
      end

      def to_partial_path
        @model._to_partial_path
      end

      def to_global_id
        URI::GID.build app: GlobalID.app, model_name: model_name.name, model_id: @id
      end
    end
    ##
    # Offer the source (ActiveFedora-based) model to Rails for some of the
    # Rails methods (e.g. link_to).
    # @example
    #   link_to '...', SolrDocument(:id => 'bXXXXXX5').new => <a href="/dams_object/bXXXXXX5">...</a>
    def to_model
      @model ||= ModelWrapper.new(hydra_model, id)
    end

    def collection?
      hydra_model == ::Collection
    end

    def suppressed?
      first(Solrizer.solr_name('suppressed', stored_boolean_field))
    end

    # Method to return the ActiveFedora model
    def hydra_model
      first(Solrizer.solr_name('has_model', :symbol)).constantize
    end

    def human_readable_type
      first(Solrizer.solr_name('human_readable_type', :stored_searchable))
    end

    def representative_id
      first(Solrizer.solr_name('hasRelatedMediaFragment', :symbol))
    end

    def thumbnail_id
      first(Solrizer.solr_name('hasRelatedImage', :symbol))
    end

    def date_modified
      date_field('date_modified')
    end

    def date_uploaded
      date_field('date_uploaded')
    end

    def depositor(default = '')
      val = first(Solrizer.solr_name('depositor'))
      val.present? ? val : default
    end

    def title
      fetch(Solrizer.solr_name('title'), [])
    end

    def description
      fetch(Solrizer.solr_name('description'), [])
    end

    def label
      first(Solrizer.solr_name('label'))
    end

    def file_format
      first(Solrizer.solr_name('file_format'))
    end

    def creator
      descriptor = hydra_model.index_config[:creator].behaviors.first
      fetch(Solrizer.solr_name('creator', descriptor), [])
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

    def keyword
      fetch(Solrizer.solr_name('keyword'), [])
    end

    def embargo_release_date
      self[Hydra.config.permissions.embargo.release_date]
    end

    def lease_expiration_date
      self[Hydra.config.permissions.lease.expiration_date]
    end

    def rights
      fetch(Solrizer.solr_name('rights'), [])
    end

    def mime_type
      self[Solrizer.solr_name('mime_type', :stored_sortable)]
    end

    def read_groups
      fetch(::Ability.read_group_field, [])
    end

    def source
      fetch(Solrizer.solr_name('source'), [])
    end

    def visibility
      @visibility ||= if embargo_release_date.present?
                        Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_EMBARGO
                      elsif lease_expiration_date.present?
                        Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_LEASE
                      elsif public?
                        Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC
                      elsif registered?
                        Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_AUTHENTICATED
                      else
                        Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE
                      end
    end

    def workflow_state
      first(Solrizer.solr_name('workflow_state_name', :symbol))
    end

    # Date created indexed as a string. This allows users to enter values like: 'Circa 1840-1844'
    def date_created
      fetch(Solrizer.solr_name("date_created"), [])
    end

    def create_date
      date_field('system_create')
    end

    def identifier
      self[Solrizer.solr_name('identifier')]
    end

    def based_near
      self[Solrizer.solr_name('based_near')]
    end

    def related_url
      self[Solrizer.solr_name('related_url')]
    end

    def resource_type
      fetch(Solrizer.solr_name("resource_type"), [])
    end

    def edit_groups
      fetch(::Ability.edit_group_field, [])
    end

    def edit_people
      fetch(::Ability.edit_user_field, [])
    end

    def collection_ids
      fetch('collection_ids_tesim', [])
    end

    def admin_set
      fetch(Solrizer.solr_name('admin_set'), [])
    end

    # Find the solr documents for the collections this object belongs to
    # TODO: can we remove this method now?
    def collections
      return @collections if @collections
      query = 'id:' + collection_ids.map { |id| '"' + id + '"' }.join(' OR ')
      result = Blacklight.default_index.connection.select(params: { q: query })
      @collections = result['response']['docs'].map do |hash|
        ::SolrDocument.new(hash)
      end
    end

    def member_of_collection_ids
      fetch(Solrizer.solr_name('member_of_collection_ids', :symbol), [])
    end

    private

      def date_field(field_name)
        field = first(Solrizer.solr_name(field_name, :stored_sortable, type: :date))
        return unless field.present?
        begin
          Date.parse(field).to_formatted_s(:standard)
        rescue
          Rails.logger.info "Unable to parse date: #{field.first.inspect} for #{self['id']}"
        end
      end

      def stored_boolean_field
        Solrizer::Descriptor.new(:boolean, :stored, :indexed)
      end
  end
end
