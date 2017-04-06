module Hyrax
  class FixityChecksController < ApplicationController
    before_action :authenticate_user!

    def create
      render json: fixity_check_service.fixity_check
    end

    protected

      def fixity_check_service
        file_set = ::FileSet.find(params[:file_set_id])
        FileSetFixityCheckService.new(file_set)
      end
  end
end
