# frozen_string_literal: true
module Hyrax
  module Forms
    class FileManagerForm
      include HydraEditor::Form
      self.terms = []
      delegate :id, :thumbnail_id, :representative_id, :to_s, to: :model
      attr_reader :current_ability, :request

      ##
      # @param work [Object] a work with members
      # @param ability [::Ability] the current ability
      # @param member_factory [Class] the member_presenter factory object to use
      #   when constructing presenters
      def initialize(work, ability, member_factory: MemberPresenterFactory)
        super(work)
        @current_ability = ability
        @request = nil
        @member_factory = member_factory
      end

      def version
        model.etag
      end

      delegate :member_presenters, to: :member_presenter_factory

      private

      def member_presenter_factory
        @member_factory.new(model, current_ability)
      end
    end
  end
end
