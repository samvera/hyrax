module Hyrax
  # Creates the presenters of the members (member works and file sets) of a specific object
  class MemberPresenterFactory
    class_attribute :file_presenter_class, :work_presenter_class
    # modify this attribute to use an alternate presenter class for the files
    self.file_presenter_class = FileSetPresenter

    # modify this attribute to use an alternate presenter class for the child works
    self.work_presenter_class = WorkShowPresenter

    # @param work [SolrDocument, Valkyrie::Resource]
    # @param ability [Ability]
    # @param request [ActionController::Request]
    def initialize(work, ability, request = nil)
      @work = work.is_a?(::SolrDocument) ? work.resource : work
      @current_ability = ability
      @request = request
    end

    delegate :id, to: :@work
    attr_reader :current_ability, :request

    # @param [Array<String>] ids a list of ids to build presenters for
    # @param [Class] presenter_class the type of presenter to build
    # @return [Array<presenter_class>] presenters for the members (not filtered by class)
    def member_presenters(ids = ordered_ids, presenter_class = composite_presenter_class)
      PresenterFactory.build_for(ids: ids,
                                 presenter_class: presenter_class,
                                 presenter_args: presenter_factory_arguments)
    end

    # @return [Array<FileSetPresenter>] presenters for the orderd_members that are FileSets
    def file_set_presenters
      @file_set_presenters ||= member_presenters(ordered_ids & file_set_ids)
    end

    # @return [Array<WorkShowPresenter>] presenters for the members that are not FileSets
    def work_presenters
      @work_presenters ||= member_presenters(ordered_ids - file_set_ids, work_presenter_class)
    end

    private

      def ordered_ids
        @work.member_ids
      end

      # These are the file sets that belong to this work in order.
      def file_set_ids
        file_sets.map(&:id)
      end

      def presenter_factory_arguments
        [current_ability, request]
      end

      def composite_presenter_class
        CompositePresenterFactory.new(file_presenter_class, work_presenter_class, ordered_ids & file_set_ids)
      end

      def file_sets
        @file_sets ||= Hyrax::Queries.find_members(resource: @work, model: ::FileSet)
      end
  end
end
