module Hyrax
  # Presents the list of work type options that a user may choose from when deciding to
  # create a new work
  class SelectTypeListPresenter
    # @param current_user [User]
    def initialize(current_user)
      @current_user = current_user
    end

    class_attribute :row_presenter
    self.row_presenter = SelectTypePresenter

    # @return [Boolean] are there many differnt types to choose?
    def many?
      authorized_models.size > 1
    end

    def authorized_models
      return [] unless @current_user
      @authorized_models ||= Hyrax::QuickClassificationQuery.new(@current_user).authorized_models
    end

    # Return or yield the first model in the list. This is used when the list
    # only has a single element.
    # @yieldparam [Class] model a class that decends from ActiveFedora::Base
    # @return [Class] a class that decends from ActiveFedora::Base
    def first_model
      yield(authorized_models.first) if block_given?
      authorized_models.first
    end

    # @yieldparam [SelectTypePresenter] presenter a presenter for the item
    def each
      authorized_models.each { |model| yield row_presenter.new(model) }
    end
  end
end
