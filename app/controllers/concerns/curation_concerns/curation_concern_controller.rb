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

    respond_to :html
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
      respond_with(:curation_concerns, curation_concern) do |wants|
        wants.html { render 'new', status: :unprocessable_entity }
      end
    end
  end

  # Finds a solr document matching the id and sets @presenter
  # @raises CanCan::AccessDenied if the document is not found
  #   or the user doesn't have access to it.
  def show
    _, document_list = search_results(params, CatalogController.search_params_logic + [:find_one])
    curation_concern = document_list.first
    raise CanCan::AccessDenied.new(nil, :show) unless curation_concern
    @presenter = show_presenter.new(curation_concern, current_ability)
  end

  # Gives the class of the show presenter. Override this if you want
  # to use a different presenter.
  def show_presenter
    CurationConcerns::GenericWorkShowPresenter
  end

  def edit
  end

  def update
    if actor.update
      after_update_response
    else
      setup_form
      respond_with(:curation_concerns, curation_concern) do |wants|
        wants.html { render 'edit', status: :unprocessable_entity }
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

    # def verify_acceptance_of_user_agreement!
    #   return true if contributor_agreement.is_being_accepted?
    #   # Calling the new action to make sure we are doing our best to preserve
    #   # the input values; Its a stretch but hopefully it'll work
    #   self.new
    #   respond_with(:curation_concern, curation_concern) do |wants|
    #     wants.html {
    #       flash.now[:error] = "You must accept the contributor agreement"
    #       render 'new', status: :conflict
    #     }
    #   end
    #   false
    # end

    def _prefixes
      @_prefixes ||= super + ['curation_concerns/base']
    end

    def after_create_response
      respond_with(main_app, :curation_concerns, curation_concern)
    end

    def after_update_response
      # TODO: visibility or lease/embargo status
      if actor.visibility_changed?
        redirect_to main_app.confirm_curation_concerns_permission_path(curation_concern)
      else
        respond_with(main_app, :curation_concerns, curation_concern)
      end
    end

    def after_destroy_response(title)
      flash[:notice] = "Deleted #{title}"
      respond_with do |wants|
        wants.html { redirect_to main_app.catalog_index_path }
      end
    end

    def attributes_for_actor
      params.fetch(hash_key_for_curation_concern, {}).permit!
    end

    def hash_key_for_curation_concern
      self.class.curation_concern_type.name.underscore.to_sym
    end
end
