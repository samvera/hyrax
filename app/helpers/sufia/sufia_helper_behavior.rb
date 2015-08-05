module Sufia
  module SufiaHelperBehavior
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

    def error_messages_for(object)
      if object.try(:errors) && object.errors.full_messages.any?
        content_tag(:div, class: 'alert alert-block alert-error validation-errors') do
          content_tag(:h4, I18n.t('sufia.errors.header', model: object.class.model_name.human.downcase), class: 'alert-heading') +
            content_tag(:ul) do
              object.errors.full_messages.map do |message|
                content_tag(:li, message)
              end.join('').html_safe
            end
        end
      else
        '' # return empty string
      end
    end

    def show_transfer_request_title(req)
      if req.deleted_work?
        req.to_s
      else
        link_to(req.to_s, curation_concerns_generic_work_path(req.generic_work_id))
      end
    end

    # You can configure blacklight to use this as the thumbnail
    # example:
    #   config.index.thumbnail_method = :sufia_thumbnail_tag
    def sufia_thumbnail_tag(document, options)
      if document.is_a?(ActiveFedora::Base)
        case document
        when Collection
          collection_thumbnail
        when GenericWork
          work_thumbnail
        else
          file_thumbnail(document, options)
        end
      elsif document.collection?
        collection_thumbnail
      elsif document.generic_work?
        work_thumbnail
      else
        file_thumbnail(document, options)
      end
    end

    # Create a link back to the dashboard screen, keeping the user's facet, query and paging choices intact by using session.
    def link_back_to_dashboard(opts = { label: 'Back to Search' })
      query_params = session[:search] ? session[:search].dup : {}
      query_params.delete :counter
      query_params.delete :total
      link_url = dashboard_index_path + "?" + query_params.to_query
      link_to opts[:label], link_url
    end

    def link_to_dashboard_query(query)
      p = params.dup
      p.delete :page
      p.delete :action
      p[:q] = query
      link_url = dashboard_index_path(p)
      link_to(query, link_url)
    end

    def has_collection_search_parameters?
      !params[:cq].blank?
    end

    def display_user_name(recent_document)
      return "no display name" unless recent_document.depositor
      ::User.find_by_user_key(recent_document.depositor).name
    rescue
      recent_document.depositor
    end

    def number_of_deposits(user)
      ActiveFedora::Base.where(Solrizer.solr_name('depositor', :symbol) => user.user_key).count
    end

    def link_to_facet(field, field_string)
      link_to(field, add_facet_params(field_string, field).merge!(controller: "catalog", action: "index"))
    end

    # @param values [Array] The values to display
    # @param solr_field [String] The name of the solr field to link to without its suffix (:facetable)
    # @param empty_message [String] ('No value entered') The message to display if no values are passed in.
    # @param separator [String] (', ') The value to join with.
    def link_to_facet_list(values, solr_field, empty_message = "No value entered", separator = ", ")
      return empty_message if values.blank?
      facet_field = Solrizer.solr_name(solr_field, :facetable)
      safe_join(values.map { |item| link_to_facet(item, facet_field) }, separator)
    end

    def link_to_field(fieldname, fieldvalue, displayvalue = nil)
      p = { search_field: 'advanced', fieldname => '"' + fieldvalue + '"' }
      link_url = main_app.catalog_index_path(p)
      display = displayvalue.blank? ? fieldvalue : displayvalue
      link_to(display, link_url)
    end

    def iconify_auto_link(text, showLink = true)
      auto_link(text) do |value|
        "<i class='glyphicon glyphicon-new-window'></i>&nbsp;#{value if showLink}<br />"
      end
    end

    def link_to_profile(login)
      user = ::User.find_by_user_key(login)
      return login if user.nil?

      text = if user.respond_to? :name
               user.name
             else
               login
             end

      link_to text, Sufia::Engine.routes.url_helpers.profile_path(user)
    end

    def linkify_chat_id(chat_id)
      if chat_id.end_with? '@chat.psu.edu'
        "<a href=\"xmpp:#{chat_id}\">#{chat_id}</a>"
      else
        chat_id
      end
    end

    def link_to_telephone(user = nil)
      @user ||= user
      link_to @user.telephone, "wtai://wp/mc;#{@user.telephone}" if @user.telephone
    end

    # Only display the current search parameters if the user is not in the dashboard.
    # If they are in the dashboard, then the search defaults to the user's files and not
    # all of Sufia.
    def current_search_parameters
      if on_the_dashboard?
        return nil
      else
        return params[:q]
      end
    end

    # Depending on which page we're landed on, we'll need to set the appropriate action url for
    # our search form.
    def search_form_action
      if on_the_dashboard?
        search_action_for_dashboard
      else
        main_app.catalog_index_path
      end
    end

    def render_visibility_link(document)
      link_to render_visibility_label(document), sufia.edit_file_set_path(document, anchor: "permissions_display"),
              id: "permission_" + document.id, class: "visibility-link"
    end

    def render_visibility_label(document)
      if document.registered?
        content_tag :span, t('sufia.institution_name'), class: "label label-info", title: t('sufia.institution_name')
      elsif document.public?
        content_tag :span, t('sufia.visibility.open'), class: "label label-success", title: t('sufia.visibility.open_title_attr')
      else
        content_tag :span, t('sufia.visibility.private'), class: "label label-danger", title: t('sufia.visibility.private_title_attr')
      end
    end

    def user_display_name_and_key(user_key)
      user = ::User.find_by_user_key(user_key)
      return user_key if user.nil?

      user.respond_to?(:name) ? "#{user.name} (#{user_key})" : user_key
    end

    private

      def search_action_for_dashboard
        case params[:controller]
        when "my/files"
          sufia.dashboard_files_path
        when "my/collections"
          sufia.dashboard_collections_path
        when "my/shares"
          sufia.dashboard_shares_path
        when "my/highlights"
          sufia.dashboard_highlights_path
        else
          sufia.dashboard_files_path
        end
      end

      def collection_thumbnail
        content_tag(:span, "", class: "glyphicon glyphicon-th collection-icon-search")
      end

      def work_thumbnail
        content_tag(:span, "", class: "glyphicon glyphicon-th collection-icon-search")
      end

      def file_thumbnail(document, options)
        path = if document.image? || document.pdf? || document.video? || document.office_document?
                 download_path document, file: 'thumbnail'
               elsif document.audio?
                 "audio.png"
               else
                 "default.png"
               end
        options[:alt] = ""
        image_tag path, options
      end
  end
end
