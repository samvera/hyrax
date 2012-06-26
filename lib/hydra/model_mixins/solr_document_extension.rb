module Hydra::ModelMixins
  module SolrDocumentExtension
    def document_type display_type = CatalogController.blacklight_config.show.display_type
      type = self.fetch(:medium_t, nil)

      type ||= self.fetch(display_type, nil) if display_type

      type.first.to_s.gsub("info:fedora/afmodel:","").gsub("Hydrangea","").gsub(/^Generic/,"")
    end
  end
end

SolrDocument.use_extension Hydra::ModelMixins::SolrDocumentExtension
