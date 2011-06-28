# Hydra::GenericImage
#
# Default content datastreams:
#   Included from Hydra::GenericContent: content, original (optional)
#   Included from Hydra::GenericImage: max, thumbnail, screen
#
# Sample Usages:
#   For good sample usage, see the documentation for HydraImage.
require "hydra"

module Hydra::GenericImage
  def self.included klass
    klass.send(:include, Hydra::GenericContent)
  end

  class Hydra::GenericImage::NoFileError < RuntimeError; end;
  class Hydra::GenericImage::UnknownImageType < RuntimeError; end;

  DEFAULT_IMAGE_DATASTREAMS = ["max","thumbnail","screen"]

  DERIVATION_DEFAULTS = {
    :max => {:op => "convert", :convertTo => "jpg"},
    :thumbnail => {:op => "resize",:newWidth=> 100},
    :screen => {:op => "resize", :newWidth => 960}
  }

  attr_accessor :derivation_overrides, :generate_derived_images
  
  def derivation_options
    if @derivation_overrides
      return DERIVATION_DEFAULTS.merge( @derivation_overrides )
    else
      return DERIVATION_DEFAULTS
    end
  end

  DEFAULT_IMAGE_DATASTREAMS.each do |ds_name|
    class_eval <<-EOM
      def has_#{ds_name}?
        self.datastreams.keys.include? "#{ds_name}"
      end

      def #{ds_name}
        datastreams["#{ds_name}"].content if has_#{ds_name}?
      end
      
      def #{ds_name}=(file)
        create_or_update_datastream("#{ds_name}",file)
      end
      
      def derive_#{ds_name}
        derive_datastream "#{ds_name}"
      end
    EOM
  end
  
  def derive_all
    DEFAULT_IMAGE_DATASTREAMS.each { |ds| self.send "derive_#{ds.to_sym}" }
  end


  private

  def delete_derivatives
    DEFAULT_IMAGE_DATASTREAMS.each { |ds| datastreams[ds].delete if datastreams.has_key? ds }
  end
  
  def derive_datastream ds_name
    ds_location = derivation_url(ds_name.to_sym, derivation_options[ds_name.to_sym])
    ds = ActiveFedora::Datastream.new(:dsid => ds_name, :label => ds_name, :dsLocation => ds_location, :controlGroup => "M", :mimeType => "image/jpeg")
    add_datastream(ds)
    save
  end

  def derivation_url ds_name, opts={}
    source_ds_name = ds_name == :max ? "content" : "max"
    raise "Oops! Cannot find source datastream." unless datastreams.keys.include? source_ds_name
    if ds_name == :max && datastreams["content"].attributes["mimeType"] == "image/jpeg"
      url = datastream_url(source_ds_name)
    else
      opts_array=[]
      opts.merge!(:url => datastream_url(source_ds_name)).each{|k,v| opts_array << "#{k}=#{v}" }
      url = "#{admin_site}imagemanip/ImageManipulation?" + opts_array.join("&")
    end
    return url
  end

  def admin_site=admin_base_url
    @admin_site = admin_base_url
  end

  def admin_site
    @admin_site ||= Fedora::Repository.instance.send(:connection).site.to_s.gsub(/fedora$/,"")
  end

  def datastream_url ds_name="content"
    "#{admin_site}fedora/objects/#{pid}/datastreams/#{ds_name}/content"
  end

end
