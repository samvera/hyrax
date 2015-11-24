module Sufia
  module CitationsBehaviors
    module Formatters
      class EndnoteFormatter < BaseFormatter
        def format(work)
          end_note_format = {
            '%T' => [:title, ->(x) { x.first }],
            '%Q' => [:title, ->(x) { x.drop(1) }],
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
            '%R' => persistent_url(work),
            '%X' => [:description],
            '%G' => [:language],
            '%[' => [:date_modified],
            '%9' => [:resource_type],
            '%~' => I18n.t('sufia.product_name'),
            '%W' => I18n.t('sufia.institution_name')
          }
          text = []
          text << "%0 GenericFile"
          end_note_format.each do |endnote_key, mapping|
            if mapping.is_a? String
              values = [mapping]
            else
              values = work.send(mapping[0]) if work.respond_to? mapping[0]
              values = mapping[1].call(values) if mapping.length == 2
              values = Array(values)
            end
            next if values.empty? || values.first.nil?
            spaced_values = values.join("; ")
            text << "#{endnote_key} #{spaced_values}"
          end
          text.join("\n")
        end
      end
    end
  end
end
