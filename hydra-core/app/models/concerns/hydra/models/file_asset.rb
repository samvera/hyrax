# will move to lib/hydra/model/file_asset_behavior in release 5.x
module Hydra
  module Models
    # Defines Behaviors for a FileAsset Model
    # Conforms to the Hydra genericContent cModel -- the "content" is in a datastream called content
    # TODO:   Could we just move this behavior into app/models/file_asset.rb? 
    module FileAsset
      extend ActiveSupport::Concern
      included do
        include Hydra::ModelMethods
        
        belongs_to :container, :class_name=>'ActiveFedora::Base', :property=>:is_part_of
        has_metadata :name => "descMetadata", :type => ActiveFedora::QualifiedDublinCoreDatastream do |m|
        end
      end


      # Returns a human readable filesize appropriate for the given number of bytes (ie. automatically chooses 'bytes','KB','MB','GB','TB')
      # Based on a bit of python code posted here: http://blogmag.net/blog/read/38/Print_human_readable_file_size
      # @param [Numeric] num file size in bits
      def bits_to_human_readable(num)
          ['bytes','KB','MB','GB','TB'].each do |x|
            if num < 1024.0
              return "#{num.to_i} #{x}"
            else
              num = num/1024.0
            end
          end
      end
      

      def label
        descMetadata.title.first
      end
          
      def label=(label)
        super
        descMetadata.title = label
      end    
      
      # augments add_file_datastream to also put file size (in bytes/KB/MB/GB/TB) in dc:extent 
      def add_file_datastream(file, opts={})
        super
        if file.respond_to?(:size)
          size = bits_to_human_readable(file.size)
        elsif file.kind_of?(File)
          size = bits_to_human_readable(File.size(file))
        else
          size = ""
        end
        datastreams["descMetadata"].extent = size
      end

      # Override ActiveFedora::Base.to_solr to...
      # Check if we are dealing with a child of FileAsset and if so when calling to_solr from Solrizer indexer we want to skip loading parent metadata again 
      #
      # if known models greater than one (without ActiveFedora::Base) and
      #   known models contains a child of FileAsset and
      #   opts[:model_only] == true and
      #   current object class is FileAsset
      # that means that the child already has had to_solr called which included metadata from FileAsset
      # if any of the above is false then call to_solr as normal
      def to_solr(solr_doc=Hash.new, opts={})

        active_fedora_model_s = solr_doc["active_fedora_model_s"] if solr_doc["active_fedora_model_s"]
        actual_class = active_fedora_model_s.constantize if active_fedora_model_s
        if actual_class && actual_class != self.class && actual_class.superclass == ::FileAsset
          solr_doc
        else
          super(solr_doc,opts)
        end
      end
    end
  end
end
