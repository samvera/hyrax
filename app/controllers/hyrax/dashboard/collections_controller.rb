# frozen_string_literal: true
module Hyrax
  module Dashboard
    ## Shows a list of all collections to the admins
    class CollectionsController < Hyrax::My::CollectionsController
      include Blacklight::AccessControls::Catalog
      include Blacklight::Base

      configure_blacklight do |config|
        config.search_builder_class = Hyrax::Dashboard::CollectionsSearchBuilder
      end

      include BreadcrumbsForCollections
      with_themed_layout 'dashboard'

      before_action :filter_docs_with_read_access!, except: [:show, :edit]
      before_action :remove_select_something_first_flash, except: :show

      include Hyrax::Collections::AcceptsBatches

      # include the render_check_all view helper method
      helper Hyrax::BatchEditsHelper
      # include the display_trophy_link view helper method
      helper Hyrax::TrophyHelper

      # Catch permission errors
      rescue_from Hydra::AccessDenied, CanCan::AccessDenied, with: :deny_collection_access

      # actions: index, create, new, edit, show, update, destroy, permissions, citation
      before_action :authenticate_user!, except: [:index]

      class_attribute :presenter_class,
                      :form_class,
                      :single_item_search_builder_class,
                      :membership_service_class

      self.presenter_class = Hyrax::CollectionPresenter

      self.form_class = Hyrax::Forms::CollectionForm

      # The search builder to find the collection
      self.single_item_search_builder_class = SingleCollectionSearchBuilder
      # The search builder to find the collections' members
      self.membership_service_class = Collections::CollectionMemberSearchService

      load_and_authorize_resource except: [:index, :create],
                                  instance_name: :collection,
                                  class: Hyrax.config.collection_model

      def deny_collection_access(exception)
        if exception.action == :edit
          redirect_to(url_for(action: 'show'), alert: 'You do not have sufficient privileges to edit this document')
        elsif current_user&.persisted?
          redirect_to root_url, alert: exception.message
        else
          session['user_return_to'] = request.url
          redirect_to main_app.new_user_session_url, alert: exception.message
        end
      end

      def new
        # Coming from the UI, a collection type id should always be present.  Coming from the API, if a collection type id is not specified,
        # use the default collection type (provides backward compatibility with versions < Hyrax 2.1.0)
        collection_type_id = params[:collection_type_id].presence || default_collection_type.id
        @collection.collection_type_gid = CollectionType.find(collection_type_id).to_global_id
        add_breadcrumb t(:'hyrax.controls.home'), root_path
        add_breadcrumb t(:'hyrax.dashboard.breadcrumbs.admin'), hyrax.dashboard_path
        add_breadcrumb t('.header', type_title: collection_type.title), request.path
        @collection.try(:apply_depositor_metadata, current_user.user_key)
        form
      end

      def show
        # @todo: remove this unused assignment in 4.0.0
        @banner_file = presenter.banner_file if collection_type.brandable?

        presenter
        query_collection_members
      end

      def edit
        form
        collection_type
      end

      def after_create
        Deprecation.warn("Method `#after_create` will be removed in Hyrax 4.0.")
        after_create_response # call private method for processing
      end

      def after_create_error
        Deprecation.warn("Method `#after_create_error` will be removed in Hyrax 4.0.")
        after_create_errors("") # call private method for processing
      end

      def create
        # Manual load and authorize necessary because Cancan will pass in all
        # form attributes. When `permissions_attributes` are present the
        # collection is saved without a value for `has_model.`
        @collection = Hyrax.config.collection_class.new
        authorize! :create, @collection

        case @collection
        when ActiveFedora::Base
          create_active_fedora_collection
        else
          create_valkyrie_collection
        end
      end

      def after_update
        Deprecation.warn("Method `#after_update` will be removed in Hyrax 4.0.")
        after_update_response # call private method for processing
      end

      def after_update_error
        Deprecation.warn("Method `#after_update_error` will be removed in Hyrax 4.0.")
        after_update_errors(@collection.errors) # call private method for processing
      end

      def update
        case @collection
        when ActiveFedora::Base
          update_active_fedora_collection
        else
          update_valkyrie_collection
        end
      end

      def process_branding
        process_banner_input
        process_logo_input
      end

      def after_destroy(_id)
        # leaving id to avoid changing the method's parameters prior to release
        respond_to do |format|
          format.html do
            redirect_to hyrax.my_collections_path,
                        notice: t('hyrax.dashboard.my.action.collection_delete_success')
          end
          format.json { head :no_content, location: hyrax.my_collections_path }
        end
      end

      def after_destroy_error(id)
        respond_to do |format|
          format.html do
            flash[:notice] = t('hyrax.dashboard.my.action.collection_delete_fail')
            render :edit, status: :unprocessable_entity
          end
          format.json { render json: { id: id }, status: :unprocessable_entity, location: dashboard_collection_path(@collection) }
        end
      end

      def destroy
        case @collection
        when Valkyrie::Resource
          valkyrie_destroy
        else
          if @collection.destroy
            after_destroy(params[:id])
          else
            after_destroy_error(params[:id])
          end
        end
      rescue StandardError => err
        Rails.logger.error(err)
        after_destroy_error(params[:id])
      end

      def collection
        action_name == 'show' ? @presenter : @collection
      end

      # Renders a JSON response with a list of files in this collection
      # This is used by the edit form to populate the thumbnail_id dropdown
      def files
        result = form.select_files.map do |label, id|
          { id: id, text: label }
        end
        render json: result
      end

      private

      def create_active_fedora_collection
        # Coming from the UI, a collection type gid should always be present.  Coming from the API, if a collection type gid is not specified,
        # use the default collection type (provides backward compatibility with versions < Hyrax 2.1.0)
        @collection.collection_type_gid = params[:collection_type_gid].presence || default_collection_type.to_global_id
        @collection.attributes = collection_params.except(:members, :parent_id, :collection_type_gid)
        @collection.apply_depositor_metadata(current_user.user_key)
        @collection.visibility = Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE unless @collection.discoverable?
        if @collection.save
          after_create_response
        else
          after_create_errors(@collection.errors)
        end
      end

      def create_valkyrie_collection
        return after_create_errors(form_err_msg(form)) unless form.validate(collection_params)

        result =
          transactions['change_set.create_collection']
          .with_step_args(
            'change_set.set_user_as_depositor' => { user: current_user },
            'change_set.add_to_collections' => { collection_ids: Array(params[:parent_id]) },
            'collection_resource.apply_collection_type_permissions' => { user: current_user }
          )
          .call(form)

        @collection = result.value_or { return after_create_errors(result.failure.first) }
        after_create_response
      end

      def update_active_fedora_collection
        process_member_changes
        process_branding

        @collection.visibility = Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE unless @collection.discoverable?
        # we don't have to reindex the full graph when updating collection
        @collection.try(:reindex_extent=, Hyrax::Adapters::NestingIndexAdapter::LIMITED_REINDEX)
        if @collection.update(collection_params.except(:members))
          after_update_response
        else
          after_update_errors(@collection.errors)
        end
      end

      def update_valkyrie_collection
        return after_update_errors(form_err_msg(form)) unless form.validate(collection_params)

        result = transactions['change_set.update_collection']
                 .with_step_args(
                          'collection_resource.save_collection_banner' => { update_banner_file_ids: params["banner_files"],
                                                                            banner_unchanged_indicator: params["banner_unchanged"] },
                          'collection_resource.save_collection_logo' => { update_logo_file_ids: params["logo_files"],
                                                                          alttext_values: params["alttext"],
                                                                          linkurl_values: params["linkurl"] }
                        )
                 .call(form)
        @collection = result.value_or { return after_update_errors(result.failure.first) }

        process_member_changes
        after_update_response
      end

      def valkyrie_destroy
        if transactions['collection_resource.destroy'].call(@collection).success?
          after_destroy(params[:id])
        else
          after_destroy_error(params[:id])
        end
      end

      def form_err_msg(form)
        errmsg = []
        form.errors.messages.each do |fld, err|
          errmsg << "#{fld} #{err.to_sentence}"
        end
        errmsg.to_sentence
      end

      def default_collection_type
        Hyrax::CollectionType.find_or_create_default_collection_type
      end

      def default_collection_type_gid
        default_collection_type.to_global_id.to_s
      end

      def collection_type
        @collection_type ||= CollectionType.find_by_gid!(collection.collection_type_gid)
      end

      def link_parent_collection(parent_id)
        child = collection.respond_to?(:valkyrie_resource) ? collection.valkyrie_resource : collection
        Hyrax::Collections::CollectionMemberService.add_member(collection_id: parent_id,
                                                               new_member: child,
                                                               user: current_user)
      end

      def uploaded_files(uploaded_file_ids)
        return [] if uploaded_file_ids.empty?
        UploadedFile.find(uploaded_file_ids)
      end

      def update_referer
        return edit_dashboard_collection_path(@collection) + (params[:referer_anchor] || '') if params[:stay_on_edit]
        dashboard_collection_path(@collection)
      end

      def process_banner_input
        return update_existing_banner if params["banner_unchanged"] == "true"
        remove_banner
        uploaded_file_ids = params["banner_files"]
        add_new_banner(uploaded_file_ids) if uploaded_file_ids
      end

      def update_existing_banner
        banner_info = CollectionBrandingInfo.where(collection_id: @collection.id.to_s).where(role: "banner")
        banner_info.first.save(banner_info.first.local_path, false)
      end

      def add_new_banner(uploaded_file_ids)
        f = uploaded_files(uploaded_file_ids).first
        banner_info = CollectionBrandingInfo.new(
          collection_id: @collection.id,
          filename: File.split(f.file_url).last,
          role: "banner",
          alt_txt: "",
          target_url: ""
        )
        banner_info.save f.file_url
      end

      def remove_banner
        banner_info = CollectionBrandingInfo.where(collection_id: @collection.id.to_s).where(role: "banner")
        banner_info&.delete_all
      end

      def update_logo_info(uploaded_file_id, alttext, linkurl)
        logo_info = CollectionBrandingInfo.where(collection_id: @collection.id.to_s).where(role: "logo").where(local_path: uploaded_file_id.to_s)
        logo_info.first.alt_text = alttext
        logo_info.first.target_url = linkurl
        logo_info.first.local_path = uploaded_file_id
        logo_info.first.save(uploaded_file_id, false)
      end

      def create_logo_info(uploaded_file_id, alttext, linkurl)
        file = uploaded_files(uploaded_file_id)
        logo_info = CollectionBrandingInfo.new(
          collection_id: @collection.id,
          filename: File.split(file.file_url).last,
          role: "logo",
          alt_txt: alttext,
          target_url: linkurl
        )
        logo_info.save file.file_url
        logo_info
      end

      def remove_redundant_files(public_files)
        # remove any public ones that were not included in the selection.
        logos_info = CollectionBrandingInfo.where(collection_id: @collection.id.to_s).where(role: "logo")
        logos_info.each do |logo_info|
          logo_info.delete(logo_info.local_path) unless public_files.include? logo_info.local_path
          logo_info.destroy unless public_files.include? logo_info.local_path
        end
      end

      def process_logo_records(uploaded_file_ids)
        public_files = []
        uploaded_file_ids.each_with_index do |ufi, i|
          # If the user has chosen a new logo, the ufi will be an integer
          # If the logo was previously chosen, the ufi will be a path
          # If it is a path, update the rec, else create a new rec
          if !ufi.match(/\D/).nil?
            update_logo_info(ufi, params["alttext"][i], verify_linkurl(params["linkurl"][i]))
            public_files << ufi
          else # brand new one, insert in the database
            logo_info = create_logo_info(ufi, params["alttext"][i], verify_linkurl(params["linkurl"][i]))
            public_files << logo_info.local_path
          end
        end
        public_files
      end

      def process_logo_input
        uploaded_file_ids = params["logo_files"]
        public_files = []

        if uploaded_file_ids.nil?
          remove_redundant_files public_files
          return
        end

        public_files = process_logo_records uploaded_file_ids
        remove_redundant_files public_files
      end

      # run a solr query to get the collections the user has access to edit
      # @return [Array] a list of the user's collections
      def find_collections_for_form
        Hyrax::CollectionsService.new(self).search_results(:edit)
      end

      def remove_select_something_first_flash
        flash.delete(:notice) if flash.notice == 'Select something first'
      end

      def presenter
        @presenter ||= presenter_class.new(curation_concern, current_ability)
      end

      def curation_concern
        # Query Solr for the collection.
        # run the solr query to find the collection members
        response, _docs = single_item_search_service.search_results
        curation_concern = response.documents.first
        raise CanCan::AccessDenied unless curation_concern
        curation_concern
      end

      def single_item_search_service
        Hyrax::SearchService.new(config: blacklight_config, user_params: params.except(:q, :page), scope: self, search_builder_class: single_item_search_builder_class)
      end

      # Instantiates the search builder that builds a query for a single item
      # this is useful in the show view.
      def single_item_search_builder
        search_service.search_builder
      end
      deprecation_deprecate :single_item_search_builder

      def collection_params
        if Hyrax.config.collection_class < ActiveFedora::Base
          @participants = extract_old_style_permission_attributes(params[:collection])
          form_class.model_attributes(params[:collection])
        else
          params.permit(collection: {})[:collection]
                .merge(params.permit(:collection_type_gid)
                             .with_defaults(collection_type_gid: default_collection_type_gid))
        end
      end

      def extract_old_style_permission_attributes(attributes)
        # TODO: REMOVE in 3.0 - part of deprecation of permission attributes
        permissions = attributes.delete("permissions_attributes")
        return [] unless permissions
        Deprecation.warn(self, "Passing in permissions_attributes parameter with a new collection is deprecated and support will be removed from Hyrax 3.0. " \
                               "Use Hyrax::PermissionTemplate instead to grant Manage, Deposit, or View access.")
        participants = []
        permissions.each do |p|
          access = access(p)
          participants << { agent_type: agent_type(p), agent_id: p["name"], access: access } if access
        end
        participants
      end

      def agent_type(permission)
        # TODO: REMOVE in 3.0 - part of deprecation of permission attributes
        return 'group' if permission["type"] == 'group'
        'user'
      end

      def access(permission)
        # TODO: REMOVE in 3.0 - part of deprecation of permission attributes
        return Hyrax::PermissionTemplateAccess::MANAGE if permission["access"] == 'edit'
        return Hyrax::PermissionTemplateAccess::VIEW if permission["access"] == 'read'
      end

      def process_member_changes
        case params[:collection][:members]
        when 'add' then add_members_to_collection
        when 'remove' then remove_members_from_collection
        when 'move' then move_members_between_collections
        end
      end

      def add_members_to_collection(collection = nil, collection_id: nil)
        collection_id ||= (collection.try(:id) || @collection.id)

        Hyrax::Collections::CollectionMemberService
          .add_members_by_ids(collection_id: collection_id,
                              new_member_ids: batch,
                              user: current_user)
      end

      def remove_members_from_collection
        Hyrax::Collections::CollectionMemberService
          .remove_members_by_ids(collection_id: @collection.id,
                                 member_ids: batch,
                                 user: current_user)
      end

      def move_members_between_collections
        remove_members_from_collection
        add_members_to_collection(collection_id: params[:destination_collection_id])

        destination_title =
          Hyrax.query_service.find_by(id: params[:destination_collection_id]).title.first ||
          params[:destination_collection_id]
        flash[:notice] = "Successfully moved #{batch.count} files to #{destination_title} Collection."
      rescue StandardError => err
        Rails.logger.error(err)
        destination_title =
          Hyrax.query_service.find_by(id: params[:destination_collection_id]).title.first ||
          destination_id
        flash[:error] = "An error occured. Files were not moved to #{destination_title} Collection."
      end

      # Include 'catalog' and 'hyrax/base' in the search path for views, while prefering
      # our local paths. Thus we are unable to just override `self.local_prefixes`
      def _prefixes
        @_prefixes ||= super + ['catalog', 'hyrax/base']
      end

      def ensure_admin!
        # Even though the user can view this collection, they may not be able to view
        # it on the admin page.
        authorize! :read, :admin_dashboard
      end

      def search_action_url(*args)
        hyrax.dashboard_collections_url(*args)
      end

      def form
        @form ||=
          case @collection
          when Valkyrie::Resource
            form = Hyrax::Forms::ResourceForm.for(@collection)
            form.prepopulate!
            form
          else
            form_class.new(@collection, current_ability, repository)
          end
      end

      def set_default_permissions
        additional_grants = @participants # Grants converted from older versions (< Hyrax 2.1.0) where share was edit or read access instead of managers, depositors, and viewers
        Collections::PermissionsCreateService.create_default(collection: @collection, creating_user: current_user, grants: additional_grants)
      end

      def query_collection_members
        member_works
        member_subcollections if collection_type.nestable?
        parent_collections if collection_type.nestable? && action_name == 'show'
      end

      # Instantiate the membership query service
      def collection_member_service
        @collection_member_service ||= membership_service_class.new(scope: self, collection: collection, params: params_for_query)
      end

      def member_works
        @response = collection_member_service.available_member_works
        @member_docs = @response.documents
        @members_count = @response.total
      end

      def member_subcollections
        results = collection_member_service.available_member_subcollections
        @subcollection_solr_response = results
        @subcollection_docs = results.documents
        @subcollection_count = @presenter.nil? ? 0 : @subcollection_count = @presenter.subcollection_count = results.total
      end

      def parent_collections
        page = params[:parent_collection_page].to_i
        query = Hyrax::Collections::NestedCollectionQueryService
        collection.parent_collections = query.parent_collections(child: collection_object, scope: self, page: page)
      end

      def collection_object
        @collection
      end

      # You can override this method if you need to provide additional
      # inputs to the search builder. For example:
      #   search_field: 'all_fields'
      # @return <Hash> the inputs required for the collection member search builder
      def params_for_query
        params.merge(q: params[:cq])
      end

      # Only accept HTTP|HTTPS urls;
      # @return <String> the url
      def verify_linkurl(linkurl)
        url = Loofah.scrub_fragment(linkurl, :prune).to_s
        url if valid_url?(url)
      end

      def valid_url?(url)
        (url =~ URI.regexp(['http', 'https']))
      end

      def after_create_response
        if @collection.is_a?(ActiveFedora::Base)
          form
          set_default_permissions
          # if we are creating the new collection as a subcollection (via the nested collections controller),
          # we pass the parent_id through a hidden field in the form and link the two after the create.
          link_parent_collection(params[:parent_id]) unless params[:parent_id].nil?
        end
        respond_to do |format|
          Hyrax::SolrService.commit
          format.html { redirect_to edit_dashboard_collection_path(@collection), notice: t('hyrax.dashboard.my.action.collection_create_success') }
          format.json { render json: @collection, status: :created, location: dashboard_collection_path(@collection) }
        end
        add_members_to_collection unless batch.empty?
      end

      def after_create_errors_for_active_fedora(errors)
        form
        respond_to do |format|
          format.html do
            flash[:error] = errors.to_s
            render action: 'new'
          end
          format.json { render json: @collection.errors, status: :unprocessable_entity }
        end
      end

      def after_create_errors(errors) # for valkyrie
        return after_create_errors_for_active_fedora(errors) if @collection.is_a? ActiveFedora::Base
        respond_to do |wants|
          wants.html do
            flash[:error] = errors.to_s
            render 'new', status: :unprocessable_entity
          end
          wants.json do
            render_json_response(response_type: :unprocessable_entity, options: { errors: errors })
          end
        end
      end

      def after_update_response
        respond_to do |format|
          format.html { redirect_to update_referer, notice: t('hyrax.dashboard.my.action.collection_update_success') }
          format.json { render json: @collection, status: :updated, location: dashboard_collection_path(@collection) }
        end
      end

      def after_update_errors_for_active_fedora(errors)
        form
        respond_to do |format|
          format.html do
            flash[:error] = errors.to_s
            render action: 'edit'
          end
          format.json { render json: @collection.errors, status: :unprocessable_entity }
        end
      end

      def after_update_errors(errors) # for valkyrie
        return after_update_errors_for_active_fedora(errors) if @collection.is_a? ActiveFedora::Base
        respond_to do |wants|
          wants.html do
            flash[:error] = errors.to_s
            render 'edit', status: :unprocessable_entity
          end
          wants.json { render_json_response(response_type: :unprocessable_entity, options: { errors: errors }) }
        end
      end
    end
  end
end
