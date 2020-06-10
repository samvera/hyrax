# frozen_string_literal: true
module Hyrax
  module SolrDocument
    module Export
      END_NOTE_MAPPINGS =
        { '%T' => [:title],
          '%A' => [:creator],
          '%C' => [:publication_place],
          '%D' => [:date_created],
          '%8' => [:date_uploaded],
          '%E' => [:contributor],
          '%I' => [:publisher],
          '%J' => [:series_title],
          '%@' => [:isbn],
          '%U' => [:related_url],
          '%7' => [:edition_statement],
          '%R' => [:persistent_url],
          '%X' => [:description],
          '%G' => [:language],
          '%[' => [:date_modified],
          '%9' => [:resource_type] }.freeze

      # MIME: 'application/x-endnote-refer'
      def export_as_endnote
        text = ["%0 #{human_readable_type}"]

        end_note_format.each do |endnote_key, mapping|
          if mapping.is_a? String
            values = [mapping]
          else
            values = send(mapping[0]) if respond_to? mapping[0]
            values = mapping[1].call(values) if mapping.length == 2
            values = Array.wrap(values)
          end
          next if values.blank? || values.first.nil?
          spaced_values = values.join("; ")
          text << "#{endnote_key} #{spaced_values}"
        end

        text.join("\n")
      end

      # Name of the downloaded endnote file
      # Override this if you want to use a different name
      def endnote_filename
        "#{id}.endnote"
      end

      def persistent_url
        "#{Hyrax.config.persistent_hostpath}#{id}"
      end

      def end_note_format
        END_NOTE_MAPPINGS.merge({ '%~' => I18n.t('hyrax.product_name'),
                                  '%W' => Institution.name })
      end
    end
  end
end
