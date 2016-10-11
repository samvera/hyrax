module Sufia
  module SufiaHelperBehavior
    include Sufia::CitationsBehavior
    include ERB::Util # provides html_escape
    extend Deprecation

    def application_name
      t('sufia.product_name', default: super)
    end

    def institution_name
      t('sufia.institution_name')
    end

    def institution_name_full
      t('sufia.institution_name_full', default: institution_name)
    end

    def orcid_label(style_class = '')
      "#{image_tag 'orcid.png', alt: t('sufia.user_profile.orcid.alt'), class: style_class} #{t('sufia.user_profile.orcid.label')}".html_safe
    end

    def zotero_label(opts = {})
      html_class = opts[:html_class] || ''
      "#{image_tag 'zotero.png', alt: t('sufia.user_profile.zotero.alt'), class: html_class} #{t('sufia.user_profile.zotero.label')}".html_safe
    end

    def zotero_profile_url(zotero_user_id)
      "https://www.zotero.org/users/#{zotero_user_id}"
    end

    # Only Chrome supports this
    # @return [Boolean]
    # @todo Replace uses with more granular client-side detection (as jQuery-fileuploader already does)
    def browser_supports_directory_upload?
      user_agent.include? 'Chrome'
    end

    def error_messages_for(object)
      return '' unless object.try(:errors) && object.errors.full_messages.any?
      content_tag(:div, class: 'alert alert-block alert-error validation-errors') do
        content_tag(:h4, I18n.t('sufia.errors.header', model: object.class.model_name.human.downcase), class: 'alert-heading') +
          content_tag(:ul) do
            object.errors.full_messages.map do |message|
              content_tag(:li, message)
            end.join('').html_safe
          end
      end
    end

    # @param [ProxyDepositRequest] req
    def show_transfer_request_title(req)
      if req.deleted_work? || req.canceled?
        req.to_s
      else
        link_to(req.to_s, req.work)
      end
    end

    # @return [Boolean]
    def has_collection_search_parameters?
      !params[:cq].blank?
    end

    # @param item [Object]
    # @param field [String]
    # @return [ActiveSupport::SafeBuffer] the html_safe link
    def link_to_facet(item, field)
      path = search_action_path(search_state.add_facet_params_and_redirect(field, item))
      link_to(item, path)
    end

    # @param values [Array{String}] strings to display
    # @param solr_field [String] name of the solr field to link to, without its suffix (:facetable)
    # @param empty_message [String] message to display if no values are passed in
    # @param separator [String] value to join with
    # @return [ActiveSupport::SafeBuffer] the html_safe link
    def link_to_facet_list(values, solr_field, empty_message = "No value entered".html_safe, separator = ", ")
      return empty_message if values.blank?
      facet_field = Solrizer.solr_name(solr_field, :facetable)
      safe_join(values.map { |item| link_to_facet(item, facet_field) }, separator)
    end

    # @param name [String] field name
    # @param value [String] field value
    # @param label [String] defaults to value
    # @param facet_hash [Hash] first argument to Blacklight::SearchState.new
    # @return [ActiveSupport::SafeBuffer] the html_safe link
    # @see Blacklight::SearchState#initialize
    def link_to_field(name, value, label = nil, facet_hash = {})
      label ||= value
      params = { search_field: name, q: "\"#{value}\"" }
      state = search_state_with_facets(params, facet_hash)
      link_to(label, main_app.search_catalog_path(state))
    end

    ## GROUP: helper_methods

    # A Blacklight helper_method
    # @param [Hash] options from blacklight invocation of helper_method
    # @see #index_field_link params
    # @return [Date]
    def human_readable_date(options)
      value = options[:value].first
      Date.parse(value).to_formatted_s(:standard)
    end

    # A Blacklight helper_method
    # @param options [Hash{Symbol=>Object}] Blacklight sends :document, :field, :config, :value and whatever else was in options
    # @option options [Array{String}] :value
    # @option options [Hash] :config including {:field_name => "my_name"}
    # @option options [Hash] :document
    # @option options [Array{String}] :value the strings you might otherwise have passed to this method singly
    # @return [ActiveSupport::SafeBuffer] the html_safe link
    def index_field_link(options)
      raise ArgumentError unless options[:config] && options[:config][:field_name]
      name = options[:config][:field_name]
      links = options[:value].map { |item| link_to_field(name, item, item) }
      safe_join(links, ", ")
    end

    # Uses Rails auto_link to add links to fields
    #
    # @param field [String,Hash] string to format and escape, or a hash as per helper_method
    # @option field [SolrDocument] :document
    # @option field [String] :field name of the solr field
    # @option field [Blacklight::Configuration::IndexField, Blacklight::Configuration::ShowField] :config
    # @option field [Array] :value array of values for the field
    # @param show_link [Boolean]
    # @return [ActiveSupport::SafeBuffer]
    # @todo stop being a helper_method, start being part of the Blacklight render stack?
    def iconify_auto_link(field, show_link = true)
      if field.is_a? Hash
        options = field[:config].separator_options || {}
        text = field[:value].to_sentence(options)
      else
        text = field
      end
      # this block is only executed when a link is inserted;
      # if we pass text containing no links, it just returns text.
      auto_link(html_escape(text)) do |value|
        "<span class='glyphicon glyphicon-new-window'></span>#{('&nbsp;' + value) if show_link}"
      end
    end

    # *Sometimes* a Blacklight helper_method
    # @param [String,User,Hash{Symbol=>Array}] args if a hash, the user_key must be under :value
    # @return [ActiveSupport::SafeBuffer] the html_safe link
    def link_to_profile(args)
      user_or_key = args.is_a?(Hash) ? args[:value].first : args
      user = case user_or_key
             when User
               user_or_key
             when String
               ::User.find_by_user_key(user_or_key)
             end
      return user_or_key if user.nil?
      text = user.respond_to?(:name) ? user.name : user_or_key
      link_to text, Sufia::Engine.routes.url_helpers.profile_path(user)
    end

    # A Blacklight helper_method
    # @param [Hash] options from blacklight helper_method invocation. Maps rights URIs to links with labels.
    # @return [ActiveSupport::SafeBuffer] rights statement links, html_safe
    def rights_statement_links(options)
      license_links(options)
    end
    deprecation_deprecate rights_statement_links: "use licence_links instead"

    # A Blacklight helper_method
    # @param [Hash] options from blacklight helper_method invocation. Maps rights URIs to links with labels.
    # @return [ActiveSupport::SafeBuffer] rights statement links, html_safe
    def license_links(options)
      service = CurationConcerns::LicenseService.new
      options[:value].map { |right| link_to service.label(right), right }.to_sentence.html_safe
    end

    def link_to_telephone(user)
      return unless user
      link_to user.telephone, "wtai://wp/mc;#{user.telephone}" if user.telephone
    end

    # Only display the current search parameters if the user is not in the dashboard.
    # Otherwise, search defaults to the user's works and not all of Sufia.
    def current_search_parameters
      return if on_the_dashboard?
      params[:q]
    end

    # @return [String] the appropriate action url for our search form (depending on our current page)
    def search_form_action
      if on_the_dashboard?
        search_action_for_dashboard
      else
        main_app.search_catalog_path
      end
    end

    def render_visibility_link(document)
      # Anchor must match with a tab in
      # https://github.com/projecthydra/sufia/blob/master/app/views/curation_concerns/base/_guts4form.html.erb#L2
      link_to render_visibility_label(document),
              edit_polymorphic_path([main_app, document], anchor: "share"),
              id: "permission_" + document.id, class: "visibility-link"
    end

    def user_display_name_and_key(user_key)
      user = ::User.find_by_user_key(user_key)
      return user_key if user.nil?
      user.respond_to?(:name) ? "#{user.name} (#{user_key})" : user_key
    end

    def collection_thumbnail(_document, _image_options = {}, _url_options = {})
      content_tag(:span, "", class: ["fa", "fa-cubes", "collection-icon-search"])
    end

    private

      def render_visibility_label(document)
        if document.registered?
          content_tag :span, institution_name, class: "label label-info", title: institution_name
        elsif document.public?
          content_tag :span, t('sufia.visibility.open'), class: "label label-success", title: t('sufia.visibility.open_title_attr')
        else
          content_tag :span, t('sufia.visibility.private'), class: "label label-danger", title: t('sufia.visibility.private_title_attr')
        end
      end

      def user_agent
        request.user_agent || ''
      end

      def search_action_for_dashboard
        case params[:controller]
        when "my/works"
          sufia.dashboard_works_path
        when "my/collections"
          sufia.dashboard_collections_path
        when "my/shares"
          sufia.dashboard_shares_path
        when "my/highlights"
          sufia.dashboard_highlights_path
        else
          sufia.dashboard_works_path
        end
      end

      # @param [ActionController::Parameters] params first argument for Blacklight::SearchState.new
      # @param [Hash] facet
      # @note Ignores all but the first facet.  Probably a bug.
      def search_state_with_facets(params, facet = {})
        state = Blacklight::SearchState.new(params, CatalogController.blacklight_config)
        return state.params if facet.none?
        state.add_facet_params(Solrizer.solr_name(facet.keys.first, :facetable),
                               facet.values.first)
      end
  end
end
