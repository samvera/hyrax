# frozen_string_literal: true
module Hyrax
  class AvatarValidator < ActiveModel::Validator
    def validate(record)
      return unless record.avatar?
      record.errors.add(:avatar_file_size, 'must be less than 2MB') if record.avatar.size > 2.megabytes.to_i
    end
  end
end
