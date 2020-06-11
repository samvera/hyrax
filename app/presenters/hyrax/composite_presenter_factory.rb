# frozen_string_literal: true
module Hyrax
  ##
  # Dynamic presenter which instantiates a file set presenter if given an object
  #   with a given ID, but otherwise instantiates a work presenter.
  class CompositePresenterFactory
    attr_reader :file_set_presenter_class, :work_presenter_class, :file_set_ids
    def initialize(file_set_presenter_class, work_presenter_class, file_set_ids)
      @file_set_presenter_class = file_set_presenter_class
      @work_presenter_class = work_presenter_class
      @file_set_ids = file_set_ids
    end

    def new(*args)
      obj = args.first
      if file_set_ids.include?(obj.id)
        file_set_presenter_class.new(*args)
      else
        work_presenter_class.new(*args)
      end
    end
  end
end
