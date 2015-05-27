module CurationConcerns
  class ClassifyConcernsController < ApplicationController
    include CurationConcerns::ThemedLayoutController
    with_themed_layout '1_column'
    respond_to :html
    before_filter :authenticate_user!
    load_and_authorize_resource

    add_breadcrumb 'Submit a work', lambda {|controller| controller.request.path }

    def classify_concern
      @classify_concern
    end
    helper_method :classify_concern

    def new
      respond_with(classify_concern)
    end

    def create
      classify_concern.attributes = params[:classify_concern]
      if classify_concern.valid?
        respond_with(classify_concern) do |wants|
          wants.html do
            redirect_to new_polymorphic_path(
              [:curation_concerns, classify_concern.curation_concern_class]
            )
          end
        end
      else
        respond_with(classify_concern)
      end
    end
  end
end
