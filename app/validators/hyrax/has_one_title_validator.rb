module Hyrax
  # validates that the title has at least one title
  class HasOneTitleValidator < ActiveModel::Validator
    def validate(record)
      return unless record.title.reject(&:empty?).empty?
      record.errors[:title] << record.errors.generate_message(:title, :missing_title)
    end
  end
end
