module Sufia
  class AvatarValidator < ActiveModel::Validator
    def validate(record)
      return unless record.avatar?
      unless record.avatar.original_size.nil?
        record.errors.add(:avatar_file_size, 'must be less than 2MB') if record.avatar.original_size > 2.megabytes.to_i
      end
    end
  end
end
