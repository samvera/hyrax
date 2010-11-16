class FileAsset < ActiveFedora::Base
  
  include Hydra::ModelMethods
  
  has_relationship "is_member_of_collection", :has_collection_member, :inbound => true
  has_bidirectional_relationship "part_of", :is_part_of, :has_part

  # deletes the object identified by pid if it does not have any objects asserting has_collection_member
  def self.garbage_collect(pid)
    begin 
      obj = FileAsset.load_instance(pid)
      if obj.containers.empty?
        obj.delete
      end
    rescue
    end
  end
  
  # @num file size in bits
  # Returns a human readable filesize appropriate for the given number of bytes (ie. automatically chooses 'bytes','KB','MB','GB','TB')
  # Based on a bit of python code posted here: http://blogmag.net/blog/read/38/Print_human_readable_file_size
  def bits_to_human_readable(num)
      ['bytes','KB','MB','GB','TB'].each do |x|
        if num < 1024.0
          return "#{num.to_i} #{x}"
        else
          num = num/1024.0
        end
      end
  end
  
  has_metadata :name => "descMetadata", :type => ActiveFedora::QualifiedDublinCoreDatastream do |m|
  end
      
  def label=(label)
    super
    datastreams_in_memory["descMetadata"].title_values = label
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
    datastreams_in_memory["descMetadata"].extent_values = size
  end

  # Mimic the relationship accessor that would be created if a containers relationship existed
  # Decided to create this method instead because it combines more than one relationship list
  # from is_member_of_collection and part_of
  # @param [Hash] opts The options hash that can contain a :response_format value of :id_array, :solr, or :load_from_solr
  # @return [Array] Objects found through inbound has_collection_member and part_of relationships
  def containers(opts={})
    is_member_array = is_member_of_collection(:response_format=>:id_array)
      
    if !is_member_array.empty?
      logger.warn "This object has inbound collection member assertions.  hasCollectionMember will no longer be used to track file_object relationships after active_fedora 1.3.  Use isPartOf assertions in the RELS-EXT of child objects instead."
      if opts[:response_format] == :solr || opts[:response_format] == :load_from_solr
        logger.warn ":solr and :load_from_solr response formats for containers search only uses parts relationships (usage of hasCollectionMember is no longer supported)"
        result = part_of(opts)
      else
        con_result = is_member_of_collection(opts)
        part_of_result = part_of(opts)
        ary = con_result+part_of_result
        result = ary.uniq
      end
    else
      result = part_of(opts)
    end
    return result
  end

  # Calls +containers+ with the :id_array option to return a list of pids for containers found.
  # @return [Array] Container ids (via is_member_of_collection and part_of relationships)
  def containers_ids
    containers(:response_format => :id_array)
  end
  
  # Calls +containers+ with the option to load objects found from solr instead of Fedora.      
  # @return [Array] ActiveFedora::Base objects populated via solr
  def containers_from_solr
    containers(:response_format => :load_from_solr)
  end
end
