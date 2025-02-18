# frozen_string_literal: true

# Any options set here are to override Rails 7.2 configuration defaults

# These fix a couple of issues arising from Rails 7.2 enforcement of HTML5 semantics
# by default when using certain Rails methods
Rails.application.config.action_view.button_to_generates_button_tag = false
Rails.application.config.action_view.sanitizer_vendor = Rails::HTML4::Sanitizer
