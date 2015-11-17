module CurationConcerns::CurationConcernController
  extend ActiveSupport::Concern
  include Blacklight::Base
  include Hydra::Controller::SearchBuilder

  included do
    copy_blacklight_config_from(CatalogController)
    include CurationConcerns::ThemedLayoutController
    with_themed_layout '1_column'
    helper CurationConcerns::AbilityHelper

    class_attribute :curation_concern_type
    attr_accessor :curation_concern
    helper_method :curation_concern
  end

  module ClassMethods
    def set_curation_concern_type(curation_concern_type)
      load_and_authorize_resource class: curation_concern_type, instance_name: :curation_concern, except: :show
      self.curation_concern_type = curation_concern_type
    end

    def cancan_resource_class
      CurationConcerns::ControllerResource
    end
  end

  def new
  end

  def create
    # return unless verify_acceptance_of_user_agreement!
    if actor.create
      after_create_response
    else
      setup_form
      respond_to do |wants|
        wants.html { render 'new', status: :unprocessable_entity }
        wants.json { render_json_response(response_type: :unprocessable_entity, options: { errors: curation_concern.errors }) }
      end
    end
  end

  # Finds a solr document matching the id and sets @presenter
  # @raises CanCan::AccessDenied if the document is not found
  #   or the user doesn't have access to it.
  def show
    respond_to do |wants|
      wants.html do
        _, document_list = search_results(params, CatalogController.search_params_logic + [:find_one])
        curation_concern = document_list.first
        raise CanCan::AccessDenied.new(nil, :show) unless curation_concern
        @presenter = show_presenter.new(curation_concern, current_ability)
      end
      wants.json do
        # load and authorize @curation_concern manually because it's skipped for html
        # This has to use #find instead of #load_instance_from_solr because
        # we want to return values like file_set_ids in the json
        @curation_concern = curation_concern_type.find(params[:id]) unless curation_concern
        authorize! :show, @curation_concern
        render :show, status: :ok
      end
    end
  end

  # Gives the class of the show presenter. Override this if you want
  # to use a different presenter.
  def show_presenter
    CurationConcerns::WorkShowPresenter
  end

  # Gives the class of the form. Override this if you want
  # to use a different form.
  def form_class
    CurationConcerns.const_get("#{self.class.curation_concern_type.to_s.demodulize}Form")
  end

  def edit
    @form = form_class.new(curation_concern, current_ability)
  end

  def update
    if actor.update
      after_update_response
    else
      setup_form
      respond_to do |wants|
        wants.html do
          @form = form_class.new(curation_concern, current_ability)
          render 'edit', status: :unprocessable_entity
        end
        wants.json { render_json_response(response_type: :unprocessable_entity, options: { errors: curation_concern.errors }) }
      end
    end
  end

  def destroy
    title = curation_concern.to_s
    curation_concern.destroy
    after_destroy_response(title)
  end

  attr_writer :actor

  protected

    def actor
      @actor ||= CurationConcerns::CurationConcern.actor(curation_concern, current_user, attributes_for_actor)
    end

    # Override setup_form in concrete controllers to get the form ready for display
    def setup_form
      return unless curation_concern.respond_to?(:contributor) && curation_concern.contributor.blank?
      curation_concern.contributor << current_user.user_key
    end

    def _prefixes
      @_prefixes ||= super + ['curation_concerns/base']
    end

    def after_create_response
      respond_to do |wants|
        wants.html { redirect_to [main_app, curation_concern] }
        wants.json { render :show, status: :created, location: polymorphic_path([main_app, curation_concern]) }
      end
    end

    def after_update_response
      # TODO: visibility or lease/embargo status
      if actor.visibility_changed? && curation_concern.file_sets.present?
        redirect_to main_app.confirm_curation_concerns_permission_path(curation_concern)
      else
        respond_to do |wants|
          wants.html { redirect_to [main_app, curation_concern] }
          wants.json { render :show, status: :ok, location: polymorphic_path([main_app, curation_concern]) }
        end
      end
    end

    def after_destroy_response(title)
      flash[:notice] = "Deleted #{title}"
      respond_to do |wants|
        wants.html { redirect_to main_app.catalog_index_path }
        wants.json { render_json_response(response_type: :deleted, message: "Deleted #{curation_concern.id}") }
      end
    end

    def attributes_for_actor
      form_class.model_attributes(params[hash_key_for_curation_concern])
    end

    def hash_key_for_curation_concern
      self.class.curation_concern_type.model_name.param_key
    end
end
