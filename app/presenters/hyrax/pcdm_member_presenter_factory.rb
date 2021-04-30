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

    ##
    # @param [#member_ids] object
    # @param [::Ability] ability
    def initialize(object, ability)
      @object = object
      @ability = ability
    end

    ##
    # @return [Array<FileSetPresenter>]
    def file_set_presenters
      []
    end

    ##
    # @return [Array<FileSetPresenter, WorkShowPresenter>]
    def member_presenters
      []
    end

    ##
    # @return [Array<WorkShowPresenter>]
    def work_presenters
      []
    end
  end
end
