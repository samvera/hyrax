# frozen_string_literal: true

module Hyrax
  ##
  # Helpers for displaying Hyrax's default contact form.
  module ContactFormHelper
    ##
    # @api public
    #
    # Provides the "issue type" options for the contact form dropdown. The
    # response should be compatible with ActionView's `options_for_select`
    # helper.
    #
    # @note this helper should always provide i18nized values.
    #
    # @return [Array<String>]
    #
    # @see https://apidock.com/rails/ActionView/Helpers/FormOptionsHelper/options_for_select
    def contact_form_issue_type_options
      Hyrax::ContactForm.issue_types_for_locale.dup
    end
  end
end
