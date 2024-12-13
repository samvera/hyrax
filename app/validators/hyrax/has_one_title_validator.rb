# frozen_string_literal: true
module Hyrax
  # validates that the title has at least one title
  class HasOneTitleValidator < ActiveModel::Validator
    def validate(record)
      return unless record.title.reject(&:empty?).empty?
      record.errors.add(:title, "You must provide a title")
    end
  end
end
