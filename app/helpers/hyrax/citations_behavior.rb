# frozen_string_literal: true

module Hyrax
  module CitationsBehavior
    include Hyrax::CitationsBehaviors::CommonBehavior
    include Hyrax::CitationsBehaviors::Formatters
    include Hyrax::CitationsBehaviors::PublicationBehavior
    include Hyrax::CitationsBehaviors::NameBehavior
    include Hyrax::CitationsBehaviors::TitleBehavior

    def export_as_apa_citation(work)
      Hyrax::CitationsBehaviors::Formatters::ApaFormatter.new(self).format(work)
    end

    def export_as_chicago_citation(work)
      Hyrax::CitationsBehaviors::Formatters::ChicagoFormatter.new(self).format(work)
    end

    def export_as_mla_citation(work)
      Hyrax::CitationsBehaviors::Formatters::MlaFormatter.new(self).format(work)
    end

    # MIME type: 'application/x-openurl-ctx-kev'
    def export_as_openurl_ctx_kev(work)
      Hyrax::CitationsBehaviors::Formatters::OpenUrlFormatter.new(self).format(work)
    end
  end
end
