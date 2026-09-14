# frozen_string_literal: true
module Hyrax
  # Creates the presenters of the members (member works and file sets) of a specific object
  class MemberPresenterFactory
    class_attribute :file_presenter_class, :work_presenter_class
    # modify this attribute to use an alternate presenter class for the files
    self.file_presenter_class = FileSetPresenter

    # modify this attribute to use an alternate presenter class for the child works
    self.work_presenter_class = WorkShowPresenter

    def initialize(work, ability, request = nil)
      @work = Hyrax::SolrDocument::OrderedMembers.decorate(work)
      @current_ability = ability
      @request = request
    end

    delegate :id, to: :@work
    attr_reader :current_ability, :request

    # @param [Array<String>] ids a list of ids to build presenters for
    # @param [Class] presenter_class the type of presenter to build
    # @return [Array<presenter_class>] presenters for the ordered_members (not filtered by class)
    def member_presenters(ids = ordered_ids, presenter_class = composite_presenter_class)
      PresenterFactory.build_for(ids: ids,
                                 presenter_class: presenter_class,
                                 presenter_args: presenter_factory_arguments)
    end

    # @return [Array<FileSetPresenter>] presenters for the orderd_members that are FileSets
    def file_set_presenters
      @file_set_presenters ||= member_presenters(ordered_ids & file_set_ids)
    end

    # @return [Array<WorkShowPresenter>] presenters for the ordered_members that are not FileSets
    def work_presenters
      @work_presenters ||= member_presenters(ordered_ids - file_set_ids, work_presenter_class)
    end

    def ordered_ids
      @work.ordered_member_ids
    end

    private

    # These are the file sets that belong to this work, but not necessarily
    # in order. Scoped to ordered_ids (already known)
    def file_set_ids
      return @file_set_ids ||= [] if ordered_ids.empty?
      query = Hyrax::SolrQueryService.new
                                     .with_ids(ids: ordered_ids)
                                     .with_field_pairs(field_pairs: { "has_model_ssim" => file_set_models }, join_with: 'OR')
                                     .build
      @file_set_ids ||= Hyrax::SolrService.query(query,
                                                   rows: ordered_ids.length,
                                                   fl: Hyrax.config.id_field)
                                          .flat_map { |x| x.fetch(Hyrax.config.id_field, []) }
    end

    def presenter_factory_arguments
      [current_ability, request]
    end

    def composite_presenter_class
      CompositePresenterFactory.new(file_presenter_class, work_presenter_class, ordered_ids & file_set_ids)
    end

    def file_set_models
      Hyrax::ModelRegistry.file_set_rdf_representations
    end
  end
end
