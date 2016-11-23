module Sufia
  module CitationsBehavior
    include Sufia::CitationsBehaviors::CommonBehavior
    include Sufia::CitationsBehaviors::Formatters
    include Sufia::CitationsBehaviors::PublicationBehavior
    include Sufia::CitationsBehaviors::NameBehavior
    include Sufia::CitationsBehaviors::TitleBehavior

    def export_as_apa_citation(work)
      Sufia::CitationsBehaviors::Formatters::ApaFormatter.new(self).format(work)
    end

    def export_as_chicago_citation(work)
      Sufia::CitationsBehaviors::Formatters::ChicagoFormatter.new(self).format(work)
    end

    def export_as_mla_citation(work)
      Sufia::CitationsBehaviors::Formatters::MlaFormatter.new(self).format(work)
    end

    # MIME type: 'application/x-openurl-ctx-kev'
    def export_as_openurl_ctx_kev(work)
      Sufia::CitationsBehaviors::Formatters::OpenUrlFormatter.new(self).format(work)
    end
  end
end
