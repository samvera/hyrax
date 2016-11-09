module Sufia
  class SelectTypeListPresenter
    # @param classification [CurationConcerns::QuickClassificationQuery]
    def initialize(classification)
      @classification = classification
    end

    class_attribute :row_presenter
    self.row_presenter = SelectTypePresenter

    def each
      @classification.each { |i| yield row_presenter.new(i) }
    end
  end
end
