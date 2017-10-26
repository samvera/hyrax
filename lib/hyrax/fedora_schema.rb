module Hyrax
  class FedoraSchema
    class_attribute :fedora_schema

    self.fedora_schema = {
      # basic metadata
      label: ActiveFedora::RDF::Fcrepo::Model.downloadFilename, # AF alert!
      relative_path: ::RDF::URI.new('http://scholarsphere.psu.edu/ns#relativePath'),
      import_url: ::RDF::URI.new('http://scholarsphere.psu.edu/ns#importUrl'),
      based_near: ::RDF::Vocab::FOAF.based_near,
      creator: ::RDF::Vocab::DC11.creator,
      contributor: ::RDF::Vocab::DC11.contributor,
      date_created: ::RDF::Vocab::DC.created,
      description: ::RDF::Vocab::DC11.description,
      keyword: ::RDF::Vocab::SCHEMA.keywords, # fixes #1505
      identifer: ::RDF::Vocab::DC.identifier,
      language: ::RDF::Vocab::DC11.language,
      license: ::RDF::Vocab::DC.rights,
      publisher: ::RDF::Vocab::DC11.publisher,
      related_url: ::RDF::Vocab::RDFS.seeAlso,
      resource_type: ::RDF::Vocab::DC11.type,
      rights_statement: ::RDF::Vocab::EDM.rights,
      subject: ::RDF::Vocab::DC11.subject,
      bibliographic_citation: ::RDF::Vocab::DC.bibliographicCitation,
      source: ::RDF::Vocab::DC.source,
      # core metadata
      date_modified: ::RDF::Vocab::DC.modified,
      date_uploaded: ::RDF::Vocab::DC.dateSubmitted,
      depositor: ::RDF::Vocab::MARCRelators.dpt,
      title: ::RDF::Vocab::DC.title,
      # representative
      representative_id: ::RDF::Vocab::EBUCore.hasRelatedMediaFragment,
      thumbnail_id: ::RDF::Vocab::EBUCore.hasRelatedImage,
      # admin_set
      admin_set_id: Hyrax.config.admin_set_predicate,
      # arkivo_checksum
      arkivo_checksum: ::RDF::URI.new('http://scholarsphere.psu.edu/ns#arkivoChecksum'),
      # proxy_deposit
      proxy_depositor: ::RDF::URI.new('http://scholarsphere.psu.edu/ns#proxyDepositor'),
      on_behalf_of: ::RDF::URI.new('http://scholarsphere.psu.edu/ns#onBehalfOf'),
      # suppressible
      state: Vocab::FedoraResourceStatus.objState,
      # work_behaviour
      owner: RDF::URI.new('http://opaquenamespace.org/ns/hydra/owner')
    }
  end
end
