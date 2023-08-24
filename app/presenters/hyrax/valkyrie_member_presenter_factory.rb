# frozen_string_literal: true
module Hyrax
  # Adapter for Valkyrie to allow the File Manager to load members.
  class ValkyrieMemberPresenterFactory
    attr_reader :current_ability, :request, :work
    def initialize(work, ability, request = nil)
      @work = work
      @current_ability = ability
      @request = request
    end

    # Return form elements for every member, so it can be passed to Simple Form.
    def member_presenters
      @member_presenters ||= Hyrax.query_service.find_members(resource: work).map do |member|
        Hyrax::Forms::ResourceForm.for(member)
      end.to_a
    end
  end
end
