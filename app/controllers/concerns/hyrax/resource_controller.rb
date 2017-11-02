# frozen_string_literal: true

module Hyrax
  # Copied from Valhalla::ResourceController
  module ResourceController
    extend ActiveSupport::Concern
    included do
      class_attribute :change_set_class, :resource_class, :change_set_persister
      delegate :metadata_adapter, to: :change_set_persister
      delegate :persister, :query_service, to: :metadata_adapter
      include Blacklight::SearchContext
    end

    def new
      @change_set = build_change_set(new_resource).prepopulate!
      authorize! :create, resource_class
    end

    def new_resource
      resource_class.new
    end

    def create
      @change_set = build_change_set(resource_class.new)
      authorize! :create, @change_set.resource
      if @change_set.validate(resource_params)
        @change_set.sync
        change_set_persister.buffer_into_index do |buffered_changeset_persister|
          @resource = buffered_changeset_persister.save(change_set: @change_set)
        end
        after_create_success(@resource, @change_set)
      else
        after_create_error(@resource, @change_set)
      end
    end

    def after_create_success(obj, change_set)
      redirect_to contextual_path(obj, change_set).show
    end

    def after_create_error(_obj, _change_set)
      render :new
    end

    def destroy
      @change_set = build_change_set(find_resource(params[:id]))
      authorize! :destroy, @change_set.resource
      change_set_persister.buffer_into_index do |persist|
        persist.delete(change_set: @change_set)
      end
      after_delete_success(@change_set)
    end

    def after_delete_success(change_set)
      flash[:alert] = "Deleted #{change_set.resource}"
      redirect_to root_path
    end

    def edit
      @change_set = build_change_set(find_resource(params[:id])).prepopulate!
      authorize! :update, @change_set.resource
    end

    def update
      @change_set = build_change_set(find_resource(params[:id])).prepopulate!
      authorize! :update, @change_set.resource
      if @change_set.validate(resource_params)
        @change_set.sync
        change_set_persister.buffer_into_index do |persist|
          @resource = persist.save(change_set: @change_set)
        end
        after_update_success(@resource, @change_set)
      else
        after_update_error(@resource, @change_set)
      end
    end

    def after_update_success(obj, change_set)
      redirect_to contextual_path(obj, change_set).show
    end

    def after_update_error(_obj, _change_set)
      render :edit
    end

    def build_change_set(resource)
      change_set_class.new(resource,
                           append_id: params[:parent_id],
                           search_context: search_context)
    end

    def search_context
      SearchContext.new(ability: current_ability,
                        repository: repository,
                        blacklight_config: blacklight_config)
    end

    def file_manager
      @change_set = change_set_class.new(find_resource(params[:id])).prepopulate!
      authorize! :file_manager, @change_set.resource
      @children = query_service.find_members(resource: @change_set).map do |x|
        change_set_class.new(x).prepopulate!
      end.to_a
    end

    def contextual_path(obj, change_set)
      Valhalla::ContextualPath.new(child: obj.id, parent_id: change_set.append_id)
    end

    def _prefixes
      @_prefixes ||= super + ['hyrax/base']
    end

    def resource_params
      raw_params = params[resource_class.model_name.param_key]
      raw_params ? raw_params.to_unsafe_h : {}
    end

    def find_resource(id)
      query_service.find_by(id: Valkyrie::ID.new(id))
    end

    # A property object for blacklight searches
    class SearchContext
      def initialize(ability:, repository:, blacklight_config:)
        @ability = ability
        @repository = repository
        @blacklight_config = blacklight_config
      end

      def user
        ability.current_user
      end

      attr_reader :ability, :repository, :blacklight_config
      alias current_ability ability
    end
  end
end
