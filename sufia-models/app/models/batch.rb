class Batch < ActiveFedora::Base
  include Hydra::AccessControls::Permissions
  include Sufia::ModelMethods
  include Sufia::Noid

  has_many :generic_files, predicate: ActiveFedora::RDF::Fcrepo::RelsExt.isPartOf

  property :creator, predicate: ::RDF::DC.creator
  property :title, predicate: ::RDF::DC.title
  property :status, predicate: ::RDF::DC.type

  def self.find_or_create(id)
    # FIXME potential race condition in this method. Consider that `find' may raise
    # ObjectNotFound in multiple processes. However, Fedora should raise an error
    # if we try to create two objects with the same id.
    begin
      Batch.find(id)
    rescue ActiveFedora::ObjectNotFoundError
      Batch.create(id: id)
    end
  end
end
