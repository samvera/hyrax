# frozen_string_literal: true
module Hyrax
  module Forms
    class FileManagerForm < Valkyrie::ChangeSet
      property :thumbnail_id
      property :representative_id
      delegate :to_s, :id, to: :model
      attr_reader :current_ability, :request

      ##
      # @param work [Object] a work with members
      # @param ability [::Ability] the current ability
      # @param member_factory [Class] the member_presenter factory object to use
      #   when constructing presenters
      def initialize(model, ability, member_factory: nil)
        super(model)
        @current_ability = ability
        @request = nil
        @member_factory = member_factory
      end

      # This ChangeSet takes either a Valkyrie object or an ActiveFedora object - ActiveFedora
      # objects don't respond to #column_for_attribute, so define it here.
      def column_for_attribute(name)
        name
      end

      def version
        model.etag
      end

      delegate :member_presenters, to: :member_presenter_factory

      private

      def member_presenter_factory
        member_factory.new(model, current_ability)
      end

      def member_factory
        @member_factory ||=
          if model.is_a?(ActiveFedora::Base)
            MemberPresenterFactory
          else
            ValkyrieMemberPresenterFactory
          end
      end
    end
  end
end
