# frozen_string_literal: true
class WorkflowActionJob < Hyrax::ApplicationJob
  def perform(comment: nil, name: false, user:, work_id:, workflow:)
    work = Hyrax.query_service.find_by(id: work_id)
    subject = ::Hyrax::WorkflowActionInfo.new(work, user)
    action = Sipity::WorkflowAction(name, workflow)

    ::Hyrax::Workflow::WorkflowActionService.run(
      subject: subject,
      action: action,
      comment: comment
    )
  end
end
