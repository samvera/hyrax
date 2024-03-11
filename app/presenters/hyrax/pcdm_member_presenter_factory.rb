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
    def initialize(object, ability, _request = nil)
      @object = object
      @ability = ability
    end

    ##
    # @return [Array<FileSetPresenter, WorkShowPresenter>]
    # @return [Enumerator<FileSetPresenter>]
    def file_set_presenters
      return enum_for(:file_set_presenters).to_a unless block_given?

      results = query_docs(generic_type: "FileSet")

      object.member_ids.each do |id|
        id = id.to_s
        indx = results.index { |doc| id == doc['id'] }
        next if indx.nil?
        hash = results.delete_at(indx)
        yield presenter_for(document: ::SolrDocument.new(hash), ability: ability)
      end
    end

    ##
    # @note defaults to using `object.member_ids`. passing a specific set of
    #   ids is supported for compatibility with {MemberPresenterFactory}, but
    #   we recommend making sparing use of this feature.
    #
    # @overload member_presenters
    #   @return [Array<FileSetPresenter, WorkShowPresenter>]
    #   @raise [ArgumentError] if an unindexed id is passed
    # @overload member_presenters
    #   @param [Array<#to_s>] ids
    #   @return [Array<FileSetPresenter, WorkShowPresenter>]
    #   @raise [ArgumentError] if an unindexed id is passed
    def member_presenters(ids = object.member_ids)
      return enum_for(:member_presenters, ids).to_a unless block_given?

      results = query_docs(ids: ids)

      ids.each do |id|
        id = id.to_s
        indx = results.index { |doc| id == doc['id'] }
        raise(Hyrax::ObjectNotFoundError, "Could not find an indexed document for id: #{id}") if
          indx.nil?
        hash = results.delete_at(indx)
        yield presenter_for(document: ::SolrDocument.new(hash), ability: ability)
      end
    end

    ##
    # @return [Array<#to_s>]
    def ordered_ids
      object.member_ids
    end

    ##
    # @return [Array<WorkShowPresenter>]
    def work_presenters
      return enum_for(:work_presenters) unless block_given?

      results = query_docs(generic_type: "Work")

      object.member_ids.each do |id|
        id = id.to_s
        indx = results.index { |doc| id == doc['id'] }
        next if indx.nil?
        hash = results.delete_at(indx)
        yield presenter_for(document: ::SolrDocument.new(hash), ability: ability)
      end
    end

    ##
    # @param [::SolrDocument] document
    # @param [::Ability] ability
    #
    # @return
    def presenter_for(document:, ability:)
      case document['has_model_ssim'].first
      when *Hyrax::ModelRegistry.file_set_rdf_representations
        file_presenter_class.new(document, ability)
      else
        work_presenter_class.new(document, ability)
      end
    end

    private

    def query_docs(generic_type: nil, ids: object.member_ids)
      query = "{!terms f=id}#{ids.join(',')}"
      query += "{!term f=generic_type_si}#{generic_type}" if generic_type
      # works created via ActiveFedora use the _sim field
      query += "{!term f=generic_type_sim}#{generic_type}" if generic_type

      Hyrax::SolrService
        .post(q: query, rows: 10_000)
        .fetch('response')
        .fetch('docs')
    end
  end
end
