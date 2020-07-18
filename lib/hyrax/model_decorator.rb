# frozen_string_literal: true
module Hyrax
  ##
  # Provides ActiveModel-safe decoration via `Draper`.
  #
  # This is needed to preserve Presenter, View, and URL
  # helper behavior for decorated models.
  #
  # @example
  #   class TitleDecorator < Hyrax::ModelDecorator
  #     ##
  #     # @return [String]
  #     def title
  #       Array(object.title).first.capitalize
  #     end
  #   end
  #
  #   my_model.title # => ['moomin']
  #   decorated = TitleDecorator.decorate(my_model)
  #
  #   decorated.title # => 'Moomin'
  #   url_helpers.download_url(decorated) == url_helpers.download_url(my_model) # => true
  #
  class ModelDecorator < Draper::Decorator
    delegate_all

    def to_model(*args)
      object.to_model(*args)
    end
  end
end
