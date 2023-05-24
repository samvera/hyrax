# frozen_string_literal: true
module Hyrax
  # Presents a list of works in workflow
  class Admin::WorkflowsController < ApplicationController
    before_action :ensure_authorized!
    with_themed_layout 'dashboard'
    class_attribute :deposited_workflow_state_name

    # Works that are in this workflow state (see workflow json template) are excluded from the
    # status list and display in the "Published" tab
    self.deposited_workflow_state_name = 'deposited'

    def index
      add_breadcrumb t(:'hyrax.controls.home'), root_path
      add_breadcrumb t(:'hyrax.dashboard.breadcrumbs.admin'), hyrax.dashboard_path
      add_breadcrumb t(:'hyrax.admin.sidebar.tasks'), '#'
      add_breadcrumb t(:'hyrax.admin.sidebar.workflow_review'), request.path
      assign_action_objects_params
      @response = WorkflowResponse.new(actionable_objects.to_a, actionable_objects.total_count, current_page, per_page, under_review?)
    end

    private

    def ensure_authorized!
      authorize! :review, :submissions
    end

    def actionable_objects
      @actionable_objects ||=
        Hyrax::Workflow::ActionableObjects.new(user: current_user)
    end

    def current_page
      @page ||= params.fetch('page', 1).to_i
    end

    def per_page
      @per_page ||= params.fetch('per_page', 10).to_i
    end

    def assign_action_objects_params
      actionable_objects.page = current_page
      actionable_objects.per_page = per_page
      actionable_objects.workflow_state_filter = (under_review? ? '!' : '') + deposited_workflow_state_name
    end

    def under_review?
      @under_review = params['state'] != 'published'
    end

    class WorkflowResponse
      attr_reader :total_count
      attr_reader :current_page
      attr_reader :per_page
      attr_reader :docs
      attr_reader :under_review

      def initialize(docs, total_count, page, per_page, under_review)
        @docs = docs
        @total_count = total_count
        @per_page = per_page.to_i
        @current_page = page.to_i
        @under_review = under_review
      end

      def total_pages
        (total_count.to_f / per_page).ceil
      end

      def limit_value
        docs.length
      end

      def viewing_under_review?
        under_review
      end
    end
  end
end
