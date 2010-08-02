class FileAsset < ActiveFedora::Base
  
  include Hydra::ModelMethods
  
  has_relationship "containers", :has_collection_member, :inbound => true
  
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
  
  def add_file_datastream(file, opts={})
    super
    datastreams_in_memory["descMetadata"].extent_values = bits_to_human_readable(file.size)
  end
  
end