# frozen_string_literal: true
module Hyrax
  module PermissionsHelper
    def help_text(file)
      capture_content(file)
    end

    private

    def capture_content(file)
      capture do
        render file
      end
    end

    def help_icon
      tag.i '', 'aria-hidden': true, class: 'help-icon'
    end
  end
end
