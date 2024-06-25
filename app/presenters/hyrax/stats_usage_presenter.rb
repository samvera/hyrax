# frozen_string_literal: true
module Hyrax
  ##
  # @abstract methods used by both {WorkUsage} and {FileUsage}
  class StatsUsagePresenter
    attr_accessor :id, :model

    def created
      @created ||= date_for_analytics
    end

    private

    def user_id
      @user_id ||= begin
                     user = Hydra::Ability.user_class.find_by_user_key(model.depositor)
                     user ? user.id : nil
                   end
    end

    def to_flots(stats)
      stats.map(&:to_flot)
    end

    # model.date_uploaded reflects the date the object was uploaded by the user
    # and therefore (if available) the date that we want to use for the stats
    # model.create_date reflects the date the file was added to Fedora. On data
    # migrated from one repository to another the created_date can be later
    # than the date the file was uploaded.
    def date_for_analytics
      earliest = Hyrax.config.analytic_start_date
      date_uploaded = string_to_date(model.date_uploaded)
      date_analytics = date_uploaded ? date_uploaded : (model.create_date || model.created_at)
      return date_analytics if earliest.blank?
      earliest > date_analytics ? earliest : date_analytics
    end

    def string_to_date(date_str)
      return date_str if date_str.is_a?(Date)
      Time.zone.parse(date_str)
    rescue ArgumentError, TypeError
      nil
    end
  end
end
