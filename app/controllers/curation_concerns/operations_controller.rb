module CurationConcerns
  class OperationsController < ApplicationController
    load_and_authorize_resource

    def index
      @operations = @operations.where(parent_id: nil)
    end

    def show
    end
  end
end
