require 'datastreams/generic_file_rdf_datastream'
require 'datastreams/properties_datastream'
require 'datastreams/file_content_datastream'

module Sufia
  module GenericFile
    extend ActiveSupport::Concern
    extend ActiveSupport::Autoload
    autoload :Export
    autoload :Thumbnail
    autoload :Characterization
    autoload :Audit
    autoload :Permissions
    include Sufia::ModelMethods
    include Sufia::Noid  
    include Sufia::GenericFile::Thumbnail
    include Sufia::GenericFile::Export
    include Sufia::GenericFile::Characterization
    include Sufia::GenericFile::Audit
    include Sufia::GenericFile::Permissions
                                                

    included do
      has_metadata :name => "descMetadata", :type => GenericFileRdfDatastream
      has_metadata :name => "properties", :type => PropertiesDatastream
      has_file_datastream :name => "content", :type => FileContentDatastream
      has_file_datastream :name => "thumbnail", :type => FileContentDatastream

      belongs_to :batch, :property => :is_part_of

      delegate_to :properties, [:relative_path, :depositor], :unique => true
      delegate_to :descMetadata, [:date_uploaded, :date_modified], :unique => true
      delegate_to :descMetadata, [:related_url, :based_near, :part_of, :creator,
                                  :contributor, :title, :tag, :description, :rights,
                                  :publisher, :date_created, :subject,
                                  :resource_type, :identifier, :language]
      around_save :characterize_if_changed, :retry_warming

      #make sure the terms of service is present and set to 1 before saving
      validates_acceptance_of :terms_of_service, :allow_nil => false
    end

    def pdf?
      ["application/pdf"].include? self.mime_type
    end

    def image?
      ["image/png","image/jpeg", 'image/jpg', 'image/bmp', "image/gif"].include? self.mime_type
    end

    def video?
      ["video/mpeg", "video/mp4", "video/x-msvideo", "video/avi", "video/quicktime"].include? self.mime_type
    end

    def persistent_url
      "#{Sufia::Engine.config.persistent_hostpath}#{noid}"
    end

    def retry_warming
        save_tries = 0
        conflict_tries = 0
        begin
          yield
        rescue RSolr::Error::Http => error
          save_tries += 1
          logger.warn "Retry Solr caught RSOLR error on #{self.pid}: #{error.inspect}"
          # fail for good if the tries is greater than 3
          raise if save_tries >=3
          sleep 0.01
          retry      
        rescue  ActiveResource::ResourceConflict => error
          conflict_tries += 1
          logger.warn "Retry caught Active Resource Conflict #{self.pid}: #{error.inspect}"
          raise if conflict_tries >=10
          sleep 0.01
          retry
        rescue =>error
          if (error.to_s.downcase.include? "conflict")
            conflict_tries += 1
            logger.warn "Retry caught Active Resource Conflict #{self.pid}: #{error.inspect}"
            raise if conflict_tries >=10
            sleep 0.01
            retry
          else
            raise
          end          
        
        end
    end

    def related_files
      relateds = begin
                   self.batch.generic_files
                 rescue NoMethodError => e
                   #batch is nil
                   batch_id = self.object_relations["isPartOf"].first || self.object_relations[:is_part_of].first
                   return [] if batch_id.nil?
                   self.class.find(:is_part_of_s => batch_id)
                 end
      relateds.reject { |gf| gf.pid == self.pid }
    end


    def to_solr(solr_doc={}, opts={})
      super(solr_doc, opts)
      solr_doc["label_t"] = self.label
      solr_doc["noid_s"] = noid
      solr_doc["file_format_t"] = file_format
      solr_doc["file_format_facet"] = solr_doc["file_format_t"]
      # remap dates as a valid xml date not to_s
      solr_doc['generic_file__date_uploaded_dt'] = Time.parse(date_uploaded).utc.to_s.sub(' ','T').sub(' UTC','Z') rescue Time.new(date_uploaded).utc.to_s.sub(' ','T').sub(' UTC','Z') unless date_uploaded.blank?
      solr_doc['generic_file__date_modified_dt'] = Time.parse(date_modified).utc.to_s.sub(' ','T').sub(' UTC','Z') rescue Time.new(date_modified).utc.to_s.sub(' ','T').sub(' UTC','Z') unless date_modified.blank?
      return solr_doc
    end

    def file_format
      return nil if self.mime_type.blank? and self.format_label.blank?
      return self.mime_type.split('/')[1]+ " ("+self.format_label.join(", ")+")" unless self.mime_type.blank? or self.format_label.blank?
      return self.mime_type.split('/')[1] unless self.mime_type.blank?
      return self.format_label
    end

    # Redefine this for more intuitive keys in Redis
    def to_param
      noid
    end

    def label=(new_label)
      @inner_object.label = new_label
      if self.title.empty?
        self.title = new_label
      end
    end

    def to_jq_upload
      return {
        "name" => self.title,
        "size" => self.file_size,
        "url" => "/files/#{noid}",
        "thumbnail_url" => self.pid,
        "delete_url" => "deleteme", # generic_file_path(:id => id),
        "delete_type" => "DELETE"
      }
    end

    def get_terms
      terms = []
      self.descMetadata.class.config[:predicate_mapping].each do |uri, mappings|
        new_terms = mappings.keys.map(&:to_s).select do |term|
          term.start_with? "generic_file__" and !['type', 'behaviors'].include? term.split('__').last
        end
        terms.concat(new_terms)
      end
      terms
    end

    def get_values
      terms = get_terms
      values = {}
      terms.each do |t|
          next if t.empty?
          key = t.to_s.split("generic_file__").last
          next if ['part_of', 'date_modified', 'date_uploaded'].include?(key)
          values[key] = self.send(key) if self.respond_to?(key)
      end        
      return values          
    end

    # Is this file in the middle of being processed by a batch?
    def processing?
       return false if self.batch.blank?
       return false if !self.batch.methods.include? :status
       return (!self.batch.status.empty?) && (self.batch.status.count == 1) && (self.batch.status[0] == "processing")
    end

    module ClassMethods
     @@FIELD_LABEL_MAP = {"based_near"=>"Location", 'description'=>"Abstract or Summary", 'tag'=>"Keyword", 'date_created'=>"Date Created", 'related_url'=>"Related URL"}

      def get_label(key)
         label = @@FIELD_LABEL_MAP[key]
         label = key.gsub('_',' ').titleize if label.blank?
         return label
      end

      # redefine find so that it sets the terms of service
      def find(args, opts={})
        gf = super
        # use the field type to see if the return will be one item or multiple
        if args.is_a? String
          gf.terms_of_service = '1'
        elsif gf.respond_to? :each
          gf.each {|f| f.terms_of_service = '1'} 
        end
        return gf
      end
    end

  end
end
