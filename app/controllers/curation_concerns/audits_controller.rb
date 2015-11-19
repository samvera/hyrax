class CurationConcerns::AuditsController < ApplicationController
  before_action :authenticate_user!
  before_action :has_access?

  def create
    render json: audit_service.audit
  end

  protected

    def audit_service
      file_set = ::FileSet.find(params[:file_set_id])
      CurationConcerns::FileSetAuditService.new(file_set)
    end
end
