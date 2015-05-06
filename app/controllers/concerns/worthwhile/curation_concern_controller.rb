module Worthwhile::CurationConcernController
  extend ActiveSupport::Concern
  include Blacklight::Catalog::SearchContext

  included do
    include Worthwhile::ThemedLayoutController
    helper Worthwhile::AbilityHelper

    class_attribute :curation_concern_type
    attr_accessor :curation_concern
    helper_method :curation_concern
    helper_method :contributor_agreement

    respond_to :html
  end

  module ClassMethods
    def set_curation_concern_type(curation_concern_type)
      load_and_authorize_resource class: curation_concern_type, instance_name: :curation_concern
      self.curation_concern_type = curation_concern_type
    end

  end

  def contributor_agreement
    @contributor_agreement ||= Worthwhile::ContributorAgreement.new(curation_concern, current_user, params)
  end


  def new
    form
  end

  def create
    if actor.create
      after_create_response
    else
      setup_form
      respond_with(form) do |wants|
        wants.html { render 'new', status: :unprocessable_entity }
      end
    end
  end

  def show
    presenter
  end

  def edit
    form
  end

  def update
    if actor.update
      after_update_response
    else
      setup_form
      respond_with([:curation_concern, curation_concern]) do |wants|
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
      @actor ||= Worthwhile::CurationConcern.actor(curation_concern, current_user, attributes_for_actor)
    end

    # Override setup_form in concrete controllers to get the form ready for display
    def setup_form
      if curation_concern.respond_to?(:contributor) && curation_concern.contributor.blank?
        curation_concern.contributor << current_user.name
      end
    end

    def _prefixes
      @_prefixes ||= super + ['curation_concern/base']
    end

    def after_create_response
      redirect_to sufia.generic_work_path(curation_concern.id)
    end

    def after_update_response
      if actor.visibility_changed?
        redirect_to sufia.generic_work_path(curation_concern.id), alert: "Your visibility was changed!"
      else
        redirect_to sufia.generic_work_path(curation_concern.id)
      end
    end

    def after_destroy_response(title)
      flash[:notice] = "Deleted #{title}"
      respond_with { |wants|
        wants.html { redirect_to main_app.catalog_index_path }
      }
    end

    def attributes_for_actor
      params[hash_key_for_curation_concern]
    end

    def hash_key_for_curation_concern
      self.class.curation_concern_type.name.split("::").last.underscore.to_sym
    end

    def form
      @form ||= form_class.new(curation_concern)
    end


    def presenter
      @presenter ||= presenter_class.new(curation_concern)
    end

  end
