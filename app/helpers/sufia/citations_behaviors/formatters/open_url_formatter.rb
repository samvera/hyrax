module Sufia
  module CitationsBehaviors
    module Formatters
      class OpenUrlFormatter < BaseFormatter
        def format(work)
          export_text = []
          export_text << "url_ver=Z39.88-2004&ctx_ver=Z39.88-2004&rft_val_fmt=info%3Aofi%2Ffmt%3Akev%3Amtx%3Adc&rfr_id=info%3Asid%2Fblacklight.rubyforge.org%3Agenerator"
          field_map = {
            title: 'title',
            creator: 'creator',
            subject: 'subject',
            description: 'description',
            publisher: 'publisher',
            contributor: 'contributor',
            date_created: 'date',
            resource_type: 'format',
            identifier: 'identifier',
            language: 'language',
            tag: 'relation',
            based_near: 'coverage',
            rights: 'rights'
          }
          field_map.each do |element, kev|
            values = work.send(element)
            next if values.blank? || values.first.nil?
            Array(values).each do |value|
              export_text << "rft.#{kev}=#{CGI.escape(value.to_s)}"
            end
          end
          export_text.join('&') unless export_text.blank?
        end
      end
    end
  end
end
