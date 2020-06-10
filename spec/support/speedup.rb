# frozen_string_literal: true
# Prevent recompiling assets in test.
# See: https://github.com/rails/rails/pull/27271
# This can be removed when we use Rails 5.1.0
class << ActionView::LookupContext::DetailsKey
  def clear; end
end
