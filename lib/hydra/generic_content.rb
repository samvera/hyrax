require "hydra"
require "httparty"
require "mime/types"

module Hydra::GenericContent
  
  def self.included(klass)
   klass.send :include, Hydra::ModelMethods
  end
  
  # For each value in DEFAULT_CONTENT_DATASTREAMS, instances will have 3 corresponding methods for
  # * getting the datastream's content
  # * setting a new file as the datastream's content
  # * checking whether the current object has the datastream already
  #
  # Example: DEFAULT_CONTENT_DATASTREAMS = ['content','original']
  # These methods will be available on the object:
  #
  # .has_original?, original, orginal=()
  # .has_content?, content, content=()
  #
  DEFAULT_CONTENT_DATASTREAMS = ['content','original']
  
  DEFAULT_CONTENT_DATASTREAMS.each do |m|
    class_eval <<-EOM
      def has_#{m}?
        self.datastreams.keys.include? "#{m}"
      end

      def #{m}
        datastreams["#{m}"].content if has_#{m}?
      end

      def #{m}=(file)
        create_or_update_datastream( "#{m}", file )
      end
    EOM
  end
    
  private

  def from_url url, ds_name
    puts "creating datastream object for: #{url}"
    ds = ActiveFedora::Datastream.new(:dsid=> ds_name, :label => ds_name, :controlGroup => "M", :dsLocation => url, :mimeType=>mime_type(url.split(/\//).last))
    add_datastream(ds)
    save
  end
  
  def from_binary binary_info, ds_name
    file =  binary_to_file(binary_info[:blob],ds_name,binary_info[:extension])
    add_file_datastream(file,:dsid=>ds_name,:label=>ds_name)
    save
  end
  
  def binary_to_file blob, suffix, ext=nil
    file_name = Time.now.strftime("%Y%m%d-%H%M%S")
    f = File.new("#{Rails.root}/tmp/#{file_name}-#{suffix}.#{ext}","w")
    f.write blob
    f.close
    return f
  end
  
  def create_or_update_datastream ds_name, file
    case file
    when File
        logger.debug "adding #{ds_name} file datastream"
        add_file_datastream(file, :dsid => ds_name, :label => ds_name, :mimeType => mime_type(file.path))
    when String
        from_url(file, ds_name)
    when Hash
      if file.has_key? :blob
        from_binary(file, ds_name)
      elsif file.has_key? :file
        add_file_datastream(file[:file], :dsid => ds_name, :label => ds_name, :mimeType => mime_type(file[:file_name]))
      end
    end
  end
  
  # Returns a human readable filesize appropriate for the given number of bytes (ie. automatically chooses 'bytes','KB','MB','GB','TB')
  # Based on a bit of python code posted here: http://blogmag.net/blog/read/38/Print_human_readable_file_size
  # @param [Numeric] file size in bits
  def bits_to_human_readable(num)
      ['bytes','KB','MB','GB','TB'].each do |x|
        if num < 1024.0
          return "#{num.to_i} #{x}"
        else
          num = num/1024.0
        end
      end
  end   
  
  # augments add_file_datastream to also put file size (in bytes/KB/MB/GB/TB) in mods:physicaldescription/mods:extent 
  def add_file_datastream(file, opts={})
    label = opts.has_key?(:label) ? opts[:label] : ""
    mimeType = opts.has_key?(:mimeType) ? opts[:mimeType] : ""
    ds = ActiveFedora::Datastream.new(:dsLabel => label, :controlGroup => 'M', :blob => file, :mimeType => mimeType)
    opts.has_key?(:dsid) ? ds.dsid=(opts[:dsid]) : nil
    add_datastream(ds)
    if file.respond_to?(:size)
      size = bits_to_human_readable(file.size)
    elsif file.kind_of?(File)
      size = bits_to_human_readable(File.size(file))
    else
      size = ""
    end
    datastreams_in_memory["descMetadata"].update_indexed_attributes( [:physical_description, :extent] => size )
  end
  
  def mime_type file_name
    mime_types = MIME::Types.of(file_name)
    mime_type = mime_types.empty? ? "application/octet-stream" : mime_types.first.content_type
  end
end
