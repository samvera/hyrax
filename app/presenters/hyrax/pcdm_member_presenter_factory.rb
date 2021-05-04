# frozen_string_literal: true
module Hyrax
  ##
  # constructs presenters for the pcdm:members of an Object, omitting those
  # not readable by a provided +Ability+.
  #
  # this implementation builds the presenters without recourse to the request
  # context and ActiveFedora-specific index structures (i.e. no `list_source`
  # or `proxy_in_ssi`).
  #
  # @see MemberPresenterFactory
  class PcdmMemberPresenterFactory
    class_attribute :file_presenter_class, :work_presenter_class
    self.file_presenter_class = FileSetPresenter
    self.work_presenter_class = WorkShowPresenter

    attr_reader :ability, :object

    ##
    # @param [#member_ids] object
    # @param [::Ability] ability
    def initialize(object, ability)
      @object = object
      @ability = ability
    end

    ##
    # @return [Array<FileSetPresenter, WorkShowPresenter>]
    # @return [Enumerator<FileSetPresenter>]
    def file_set_presenters
      return enum_for(:file_set_presenters) unless block_given?

      query_docs(generic_type: "FileSet").each do |result|
        yield presenter_for(document: ::SolrDocument.new(result), ability: ability)
      end
    end

    ##
    # @return [Enumerator<FileSetPresenter, WorkShowPresenter>]
    def member_presenters
      return enum_for(:member_presenters) unless block_given?

      query_docs.each do |result|
        yield presenter_for(document: ::SolrDocument.new(result), ability: ability)
      end
    end

    ##
    # @return [Array<WorkShowPresenter>]
    def work_presenters
      return enum_for(:work_presenters) unless block_given?

      query_docs(generic_type: "Work").each do |result|
        yield presenter_for(document: ::SolrDocument.new(result), ability: ability)
      end
    end

    ##
    # @param [::SolrDocument] document
    # @param [::Ability] ability
    #
    # @return
    def presenter_for(document:, ability:)
      case document['has_model_ssim'].first
      when Hyrax::FileSet.name
        Hyrax::FileSetPresenter.new(document, ability)
      else
        Hyrax::WorkShowPresenter.new(document, ability)
      end
    end

    private

    def query_docs(generic_type: nil)
      query = "{!terms f=id}#{object.member_ids.join(',')}"
      query += "{!term f=generic_type_si}#{generic_type}" if generic_type

      Hyrax::SolrService
        .post(query, rows: 10_000)
        .fetch('response')
        .fetch('docs')
    end
  end
end
