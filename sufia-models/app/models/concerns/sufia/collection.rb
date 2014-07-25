module Sufia
  module Collection
    extend ActiveSupport::Concern
    include Hydra::Collection
    include Sufia::ModelMethods
    include Sufia::Noid
    include Sufia::GenericFile::Permissions
    include Sufia::GenericFile::WebForm # provides initialize_fields method

    included do
      before_save :update_permissions
      validates :title, presence: true

      has_metadata "properties", type: PropertiesDatastream
    end

    def terms_for_display
      terms_for_editing - [:title, :description]
    end

    def terms_for_editing
      [:resource_type, :title, :creator, :contributor, :description, :tag,
        :rights, :publisher, :date_created, :subject, :language, :identifier,
        :based_near, :related_url]
    end

    # Test to see if the given field is required
    # @param [Symbol] key a field
    # @return [Boolean] is it required or not
    def required?(key)
      self.class.validators_on(key).any?{|v| v.kind_of? ActiveModel::Validations::PresenceValidator}
    end

    def to_param
      noid
    end

    def to_solr(solr_doc={}, opts={})
      super(solr_doc, opts)
      solr_doc[Solrizer.solr_name("noid", Sufia::GenericFile.noid_indexer)] = noid
      return solr_doc
    end

    def update_permissions
      self.visibility = "open"
    end

    # Compute the sum of each file in the collection
    # Return an integer of the result
    def bytes
      members.reduce(0) { |sum, gf| sum + gf.file_size.first.to_i }
    end

  end
end
