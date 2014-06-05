module Hydra
  class FutureDateValidator < ActiveModel::EachValidator

    def validate_each(record, attribute, value)
      if value.present?
        begin
          if date = value.to_date
            if date <= Date.today
              record.errors[:embargo_release_date] << "Must be a future date"
            end
          else
            record.errors[:embargo_release_date] << "Invalid Date Format"
          end
        rescue ArgumentError, NoMethodError
          record.errors[:embargo_release_date] << "Invalid Date Format"
        end
      end
    end
  end
end
