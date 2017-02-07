module CurationConcerns
  module Forms
    class FileManagerForm
      include HydraEditor::Form
      self.terms = []
      delegate :id, :thumbnail_id, :representative_id, :to_s, to: :model
      attr_reader :current_ability, :request
      def initialize(work, ability)
        super(work)
        @current_ability = ability
        @request = nil
      end

      def version
        model.etag
      end

      delegate :member_presenters, to: :member_presenter_factory

      private

        def member_presenter_factory
          MemberPresenterFactory.new(work, ability)
        end
    end
  end
end
