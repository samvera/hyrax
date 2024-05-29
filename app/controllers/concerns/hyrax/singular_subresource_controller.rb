# frozen_string_literal: true
module Hyrax
  module SingularSubresourceController
    extend ActiveSupport::Concern
    include DenyAccessOverrideBehavior

    included do
      before_action :find_work, only: :work
      before_action :find_file_set, only: :file
      load_and_authorize_resource :work, only: :work
      load_and_authorize_resource :file, only: :file
    end

    def find_work
      @work = Hyrax.query_service.find_by(id: params[:id])
    end

    def find_file_set
      @file = Hyrax.query_service.find_by(id: params[:id])
    end
  end
end
