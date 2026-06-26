# frozen_string_literal: true
module Hyrax
  class FileSetPresenter
    include ModelProxy
    include PresentsAttributes
    include CharacterizationBehavior
    include WithEvents
    include DisplaysImage
    include MissingMethodBehavior
    include DisplaysTranscripts

    attr_accessor :solr_document, :current_ability, :request

    # @param [SolrDocument] solr_document
    # @param [Ability] current_ability
    # @param [ActionDispatch::Request] request the http request context
    def initialize(solr_document, current_ability, request = nil)
      @solr_document = solr_document
      @current_ability = current_ability
      @request = request
      define_dynamic_methods if solr_document.try(:flexible?)
    end

    delegate :to_s, to: :solr_document
    delegate :member_of_collection_ids, to: :parent

    def workflow
      nil
    end

    def model
      solr_document.to_model
    end

    def single_use_links
      @single_use_links ||= SingleUseLink.where(item_id: id).map { |link| link_presenter_class.new(link) }
    end

    # The title of the webpage that shows this FileSet.
    def page_title
      "#{human_readable_type} | #{title.first} | ID: #{id} | #{I18n.t('hyrax.product_name')}"
    end

    # The first title assertion
    def first_title
      title.first
    end

    # The link text when linking to the show page of this FileSet
    def link_name
      current_ability.can?(:read, id) ? first_title : 'File'
    end

    ##
    # @deprecated use `::Ability.can?(:edit, presenter)`. Hyrax views calling
    #   presenter {#editor} methods will continue to call them until Hyrax
    #   4.0.0. The deprecation time horizon for the presenter methods themselves
    #   is 5.0.0.
    def editor?
      current_ability.can?(:edit, self)
    end

    def tweeter
      TwitterPresenter.twitter_handle_for(user_key: depositor)
    end

    def license
      return if solr_document.license.nil?
      solr_document.license.first
    end

    def stats_path
      Hyrax::Engine.routes.url_helpers.stats_file_path(self, locale: I18n.locale)
    end

    def events(size = 100)
      super(size)
    end

    # This overrides the method in WithEvents
    def event_class
      solr_document.to_model.model_name.name
    end

    def fixity_check_status
      Hyrax::FixityStatusPresenter.new(id).render_file_set_status
    end

    ##
    # @return [WorkShowPresenter, nil] +nil+ if no parent can be found
    def parent
      @parent_presenter ||= fetch_parent_presenter
    end

    def user_can_perform_any_action?
      Deprecation.warn("We're removing Hyrax::FileSetPresenter.user_can_perform_any_action? in Hyrax 4.0.0; Instead use can? in view contexts.")
      current_ability.can?(:edit, id) || current_ability.can?(:destroy, id) || current_ability.can?(:download, id)
    end

    ##
    # @return [Array<String>]
    def show_partials
      %w[show_details metadata]
    end

    private

    def link_presenter_class
      SingleUseLinkPresenter
    end

    def fetch_parent_presenter
      ids = Hyrax::SolrService.query("{!field f=member_ids_ssim}#{id}", fl: Hyrax.config.id_field, rows: 1)
                              .map { |x| x.fetch(Hyrax.config.id_field) }
      if ids.empty?
        Hyrax.logger.warn("Couldn't find a parent work for FileSet: #{id}.")
      else
        doc = ::SolrDocument.find(ids.first)
        unless current_ability.can?(:edit, doc)
          raise WorkflowAuthorizationException if doc.suppressed? && current_ability.can?(:read, doc)
        end
      end
      Hyrax::PresenterFactory.build_for(ids: ids,
                                        presenter_class: WorkShowPresenter,
                                        presenter_args: current_ability).first
    end

    # Define a reader for each flexible-profile property that carries indexing
    # keys, reading the first present indexed value off the Solr document.
    # Mirrors WorkShowPresenter#define_dynamic_methods, but defines the readers
    # directly on the presenter because a FileSet's SolrDocument is not
    # OrderedMembers-decorated. current_version is read once here (not per
    # property), matching the work presenter.
    def define_dynamic_methods # rubocop:disable Metrics/MethodLength
      Hyrax::FlexibleSchema.current_version["properties"].each do |method_name, property_details|
        index_keys = property_details["indexing"]
        next unless index_keys
        next if self.class.method_defined?(method_name)

        multi_value = property_details["multiple"] || (property_details["data_type"] == "array")
        self.class.send(:define_method, method_name) do |*_args|
          index_keys.each do |index_key|
            value = solr_document[index_key]
            return(multi_value ? Array.wrap(value) : value) if value.present?
          end
          multi_value ? [] : ""
        end
      end
    end
  end
end
