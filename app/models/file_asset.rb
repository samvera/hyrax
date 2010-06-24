class FileAsset < ActiveFedora::Base
  
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
  
  has_metadata :name => "DC", :type => ActiveFedora::QualifiedDublinCoreDatastream do |m|
  end
      
  def label=(label)
    super
    datastreams_in_memory["DC"].title_values = label
  end    
  
  def add_file_datastream(file, opts={})
    super
    datastreams_in_memory["DC"].extent_values = bits_to_human_readable(file.size)
  end
  
  def save
    super
    if defined?(Solrizer::Solrizer)
      solrizer = Solrizer::Solrizer.new
      solrizer.solrize( self )
    end
  end
  
end