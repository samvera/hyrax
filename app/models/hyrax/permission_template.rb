module Hyrax
  # Defines behavior that is applied to objects added as members of an AdminSet
  #
  #  * access rights to stamp on each object
  #  * calculate embargo/lease release dates
  #
  # There is an interplay between an AdminSet and a PermissionTemplate.
  #
  # @see Hyrax::AdminSetBehavior for further discussion
  class PermissionTemplate < ActiveRecord::Base
    self.table_name = 'permission_templates'

    has_many :access_grants, class_name: 'Hyrax::PermissionTemplateAccess', dependent: :destroy
    accepts_nested_attributes_for :access_grants, reject_if: :all_blank

    has_many :workflows, class_name: 'Sipity::Workflow', dependent: :destroy

    # A bit of an analogue for a `belongs_to :admin_set` as it crosses from Fedora to the DB
    # @return [AdminSet]
    # @raise [ActiveFedora::ObjectNotFoundError] when the we cannot find the AdminSet
    def admin_set
      AdminSet.find(admin_set_id)
    end

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

    # Key/value pair of valid embargo periods. Values are number of months embargoed.
    RELEASE_EMBARGO_PERIODS = {
      RELEASE_TEXT_VALUE_6_MONTHS => 6,
      RELEASE_TEXT_VALUE_1_YEAR => 12,
      RELEASE_TEXT_VALUE_2_YEARS => 24,
      RELEASE_TEXT_VALUE_3_YEARS => 36
    }.freeze

    # Does this permission template require a specific date of release for all works
    # NOTE: date will be in release_date
    def release_fixed_date?
      release_period == RELEASE_TEXT_VALUE_FIXED
    end

    # Does this permission template require no release delays (i.e. no embargoes allowed)
    def release_no_delay?
      release_period == RELEASE_TEXT_VALUE_NO_DELAY
    end

    # Does this permission template require a date (or embargo) that all works are released before
    # NOTE: date will be in release_date
    def release_before_date?
      # All PermissionTemplate embargoes are dynamically determined release before dates
      release_period == RELEASE_TEXT_VALUE_BEFORE_DATE || release_max_embargo?
    end

    # Is there a maximum embargo period specified by this permission template
    # NOTE: latest embargo date returned by release_date, maximum embargo period will be in release_period
    def release_max_embargo?
      # Is it a release period in one of our valid embargo periods?
      RELEASE_EMBARGO_PERIODS.key?(release_period)
    end

    # Override release_date getter to return a dynamically calculated date of release
    # based one release requirements. Returns embargo date when release_max_embargo?==true.
    # Returns today's date when release_no_delay?==true.
    # @see Hyrax::AdminSetService for usage
    def release_date
      # If no release delays allowed, return today's date as release date
      return Time.zone.today if release_no_delay?

      # If this isn't an embargo, just return release_date from database
      return self[:release_date] unless release_max_embargo?

      # Otherwise (if an embargo), return latest embargo date by adding specified months to today's date
      Time.zone.today + RELEASE_EMBARGO_PERIODS.fetch(release_period).months
    end

    # Determines whether a given release date is valid based on this template's requirements
    # @param [Date] date to validate
    def valid_release_date?(date)
      # Validate date against all release date requirements
      check_no_delay_requirements(date) && check_before_date_requirements(date) && check_fixed_date_requirements(date)
    end

    # Determines whether a given visibility setting is valid based on this template's requirements
    # @param [String] visibility value to validate
    def valid_visibility?(value)
      # If template doesn't specify a visiblity (i.e. is "varies"), then any visibility is valid
      return true unless visibility.present?

      # Validate that passed in value matches visibility requirement exactly
      visibility == value
    end

    private

      # If template requires no delays, check if date is exactly today
      def check_no_delay_requirements(date)
        return true unless release_no_delay?
        date == Time.zone.today
      end

      # If template requires a release before a specific date, check this date is valid
      def check_before_date_requirements(date)
        return true unless release_before_date? && release_date.present?
        date <= release_date
      end

      # If template requires an exact date, check this date matches
      def check_fixed_date_requirements(date)
        return true unless release_fixed_date? && release_date.present?
        date == release_date
      end
  end
end
