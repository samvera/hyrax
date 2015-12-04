module CurationConcerns
  module PermissionsHelper
    def help_link(file, title, aria_label)
      link_to help_icon, '#', 'data-toggle': 'popover', 'data-content': capture_content(file),
                              'data-original-title': title, 'aria-label': aria_label
    end

    private

      def capture_content(file)
        capture do
          render file
        end
      end

      def help_icon
        content_tag 'i', '', 'aria-hidden': true, class: 'help-icon'
      end
  end
end
