module Hyrax
  module ContentBlockBehavior
    extend ActiveSupport::Concern

    MARKETING  = 'marketing_text'.freeze
    RESEARCHER = 'featured_researcher'.freeze
    ANNOUNCEMENT = 'announcement_text'.freeze
    ABOUT = 'about_page'.freeze
    HELP = 'help_page'.freeze

    def external_key_name
      self.class.external_keys.fetch(name) { 'External Key' }
    end

    class_methods do
      def marketing_text
        find_or_create_by(name: MARKETING)
      end

      def marketing_text=(value)
        marketing_text.update(value: value)
      end

      def announcement_text
        find_or_create_by(name: ANNOUNCEMENT)
      end

      def announcement_text=(value)
        announcement_text.update(value: value)
      end

      def recent_researchers
        where(name: RESEARCHER).order('created_at DESC')
      end

      def featured_researcher
        recent_researchers.first_or_create(name: RESEARCHER)
      end

      def featured_researcher=(value)
        create(name: RESEARCHER, value: value)
      end

      def external_keys
        { RESEARCHER => 'User' }
      end

      def about_page
        find_or_create_by(name: ABOUT)
      end

      def about_page=(value)
        about_page.update(value: value)
      end

      def help_page
        find_or_create_by(name: HELP)
      end

      def help_page=(value)
        help_page.update(value: value)
      end
    end
  end
end
