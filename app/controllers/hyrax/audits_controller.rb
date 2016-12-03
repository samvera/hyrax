module Hyrax
  class AuditsController < ApplicationController
    before_action :authenticate_user!

    def create
      render json: audit_service.audit
    end

    protected

      def audit_service
        file_set = ::FileSet.find(params[:file_set_id])
        FileSetAuditService.new(file_set)
      end
  end
end
