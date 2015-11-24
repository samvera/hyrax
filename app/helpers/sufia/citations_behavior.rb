module Sufia
  module CitationsBehavior
    include Sufia::CitationsBehaviors::CommonBehavior
    include Sufia::CitationsBehaviors::Formatters
    include Sufia::CitationsBehaviors::PublicationBehavior
    include Sufia::CitationsBehaviors::NameBehavior
    include Sufia::CitationsBehaviors::TitleBehavior

    def export_as_apa_citation(work)
      ApaFormatter.new.format(work)
    end

    def export_as_chicago_citation(work)
      ChicagoFormatter.new.format(work)
    end

    # MIME: 'application/x-endnote-refer'
    def export_as_endnote(work)
      EndnoteFormatter.new.format(work)
    end

    def export_as_mla_citation(work)
      MlaFormatter.new.format(work)
    end

    # MIME type: 'application/x-openurl-ctx-kev'
    def export_as_openurl_ctx_kev(work)
      OpenUrlFormatter.new.format(work)
    end
  end
end
