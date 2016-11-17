module CurationConcerns
  # Behavior to allow any controller to be displayed within
  # the administrative dashboard
  #
  # Example useage:
  #
  #    module CurationConcerns
  #      class Admin::MyController < ApplicationController
  #        include CurationConcerns::ActAsAdminController
  #
  #        # do my stuff ...
  #      end
  #    end
  #
  module ActAsAdminController
    extend ActiveSupport::Concern
    included do
      before_action :load_configuration
      layout 'admin'
    end
    def load_configuration
      @configuration = CurationConcerns::AdminController.configuration
    end
  end
end
