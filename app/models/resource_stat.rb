# Responsible for caching statistics from remote analytics platforms such as Google Analytics and Matomo. This class
# will hold statistics for various resource_type's such as `Works` `FileSets`  `Collections` as well as site-wide
# metrics.
# @note The only required field for an entry is a date. Other combinations will require additional fields, such as a
# `user_id` and a `resource_id`. But that is dependent on context and documented in the scopes and related tests.
class ResourceStat < ApplicationRecord
  validates :date, presence: true
end
