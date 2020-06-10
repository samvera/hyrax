# frozen_string_literal: true
module Hyrax
  class OperationsController < ApplicationController
    load_and_authorize_resource

    def index
      @operations = @operations.where(parent_id: nil)
                               .order(updated_at: :desc)
                               .page(params[:page])
    end

    def show; end
  end
end
