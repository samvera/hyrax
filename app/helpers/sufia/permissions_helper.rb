module Sufia
  module PermissionsHelper
    def visibility_help
      help_link('curation_concerns/file_sets/visibility', 'Visibility', 'Usage information for visibility')
    end

    def share_with_help
      help_link('curation_concerns/file_sets/share_with', 'Share With', 'Usage information for sharing')
    end

    private

      def help_link(file, title, aria_label)
        link_to help_icon, '#', rel: 'popover', 'data-content': capture_content(file),
                                'data-original-title': title, 'aria-label': aria_label
      end

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
