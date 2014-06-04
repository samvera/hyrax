module Worthwhile
  module ManagesEmbargoes
    extend ActiveSupport::Concern

    included do
      include Worthwhile::ThemedLayoutController
      with_themed_layout '1_column'

      attr_accessor :curation_concern
      helper_method :curation_concern
      load_and_authorize_resource class: ActiveFedora::Base, instance_name: :curation_concern
    end


    def index
      authorize! :discover, :embargo
    end

    def edit
    end
  end
end
