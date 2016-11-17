module CurationConcerns
  class ClassifyConcernsController < ApplicationController
    include CurationConcerns::ThemedLayoutController
    with_themed_layout '1_column'
    before_action :authenticate_user!
    load_and_authorize_resource

    add_breadcrumb 'Submit a work', ->(controller) { controller.request.path }

    attr_reader :classify_concern
    helper_method :classify_concern

    def new
    end

    def create
      classify_concern.attributes = params[:classify_concern]
      if classify_concern.valid?
        respond_to do |wants|
          wants.html do
            redirect_to new_polymorphic_path(
              [:curation_concerns, classify_concern.curation_concern_class]
            )
          end
          wants.json { render_json_response(response_type: :created, options: { location: polymorphic_path([main_app, :curation_concerns, curation_concern]) }) }
        end
      else
        respond_to do |wants|
          wants.html { render 'new', status: :unprocessable_entity }
          wants.json { render_json_response(response_type: :unprocessable_entity, message: curation_concern.errors.messages) }
        end
      end
    end
  end
end
