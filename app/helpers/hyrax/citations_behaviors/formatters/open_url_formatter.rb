# frozen_string_literal: true
module Hyrax
  module CitationsBehaviors
    module Formatters
      class OpenUrlFormatter < BaseFormatter
        def format(work)
          export_text = []
          export_text << "url_ver=Z39.88-2004&ctx_ver=Z39.88-2004&rft_val_fmt=info%3Aofi%2Ffmt%3Akev%3Amtx%3Adc&rfr_id=info%3Asid%2Fblacklight.rubyforge.org%3Agenerator"
          FIELD_MAP.each do |element, kev|
            next unless work.respond_to?(element)
            values = work.send(element)
            Array.wrap(values).each do |value|
              next if value.blank?
              export_text << "rft.#{kev}=#{CGI.escape(value.to_s)}"
            end
          end
          export_text.join('&') if export_text.present?
        end

        FIELD_MAP = {
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
          keyword: 'relation',
          based_near: 'coverage',
          license: 'license'
        }.freeze
      end
    end
  end
end
