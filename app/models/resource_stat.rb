# Responsible for caching statistics from remote analytics platforms such as Google Analytics and Matomo. This class
# will hold statistics for various resource_type's such as `Works` `FileSets`  `Collections` as well as site-wide
# metrics.
# @note The only required field for an entry is a date. Other combinations will require additional fields, such as a
# `user_id` and a `resource_id`. But that is dependent on context and documented in the scopes and related tests.
class ResourceStat < ApplicationRecord
  validates :date, presence: true

  # Daily statistics for a given resource (Work, FileSet) associated with a User
  scope :resource_daily_stats, ->(date, resource_id, user_id) { where('date = ? AND resource_id = ? AND user_id = ?', date, resource_id, user_id) }
  # Daily statistics for the site
  scope :site_daily_stats, ->(date) { where('date = ? AND resource_id IS NULL AND user_id IS NULL', date) }

  # Statistics for a given resource (Work, FileSet) associated with a User, in a time range
  scope :resource_range_stats, ->(start_date, end_date, resource_id, user_id) { where('date BETWEEN ? AND ? AND resource_id = ? AND user_id = ?', start_date, end_date, resource_id, user_id) }
  # Statistics for the site, in a time range
  scope :site_range_stats, ->(start_date, end_date) { where('date BETWEEN ? AND ? AND resource_id IS NULL AND user_id IS NULL', start_date, end_date) }

  # Queries for Hyrax::Statistics queries

  # Unique visitors for the site
  scope :site_sessions, -> { select('sessions').where('resource_id IS NULL AND user_id IS NULL') }
  scope :site_visitors, -> { select('visitors').where('resource_id IS NULL AND user_id IS NULL') }
end
