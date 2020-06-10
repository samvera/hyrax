# frozen_string_literal: true
module Hyrax
  # Repeatable logic for presenting twitter handles.
  #
  # @note The duplication of code was found via the flay gem
  module TwitterPresenter
    # @api public
    # @param [String] user_key for which we will find the appropriate twitter handle
    # @return [String] the twitter handle appropriate for the given user key
    def self.twitter_handle_for(user_key:)
      user = ::User.find_by_user_key(user_key)
      if user.try(:twitter_handle).present?
        "@#{user.twitter_handle}"
      else
        I18n.translate('hyrax.product_twitter_handle')
      end
    end
  end
end
