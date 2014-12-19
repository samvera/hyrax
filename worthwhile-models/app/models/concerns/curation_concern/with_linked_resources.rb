module CurationConcern
  module WithLinkedResources
    extend ActiveSupport::Concern

    included do

      # attribute :linked_resource_urls, multiple: true
      attr_accessor :linked_resource_urls

      has_many :linked_resources, predicate: ActiveFedora::RDF::Fcrepo::RelsExt.isPartOf, class_name:"Worthwhile::LinkedResource"

      before_destroy :before_destroy_cleanup_linked_resources
    end

    def before_destroy_cleanup_linked_resources
      linked_resources.each(&:destroy)
    end

  end
end

