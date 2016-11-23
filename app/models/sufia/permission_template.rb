module Sufia
  class PermissionTemplate < ActiveRecord::Base
    has_many :access_grants, class_name: 'Sufia::PermissionTemplateAccess'
    accepts_nested_attributes_for :access_grants, reject_if: :all_blank

    # Valid Release Period values
    RELEASE_TEXT_VALUE_FIXED = 'fixed'.freeze
    RELEASE_TEXT_VALUE_NO_DELAY = 'now'.freeze

    # Valid Release Varies sub-options
    RELEASE_TEXT_VALUE_BEFORE_DATE = 'before'.freeze
    RELEASE_TEXT_VALUE_EMBARGO = 'embargo'.freeze
    RELEASE_TEXT_VALUE_6_MONTHS = '6mos'.freeze
    RELEASE_TEXT_VALUE_1_YEAR = '1yr'.freeze
    RELEASE_TEXT_VALUE_2_YEARS = '2yrs'.freeze
    RELEASE_TEXT_VALUE_3_YEARS = '3yrs'.freeze

    # Does this permission template require a specific date of release for all works
    # NOTE: date will be in release_date
    def release_fixed?
      release_period == RELEASE_TEXT_VALUE_FIXED
    end

    # Does this permission template require no release delays (i.e. no embargoes allowed)
    def release_no_delay?
      release_period == RELEASE_TEXT_VALUE_NO_DELAY
    end

    # Does this permission template require a date that all works are released before
    # NOTE: date will be in release_date
    def release_before_date?
      release_period == RELEASE_TEXT_VALUE_BEFORE_DATE
    end

    # Is a specific embargo period required by this permission template
    # NOTE: embargo period will be in release_period
    def release_embargo?
      release_period == RELEASE_TEXT_VALUE_6_MONTHS ||
        release_period == RELEASE_TEXT_VALUE_1_YEAR ||
        release_period == RELEASE_TEXT_VALUE_2_YEARS ||
        release_period == RELEASE_TEXT_VALUE_3_YEARS
    end
  end
end
