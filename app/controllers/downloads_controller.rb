class DownloadsController < ApplicationController
  include PSU::Noid

  before_filter :deny_access_if_not_reader, :only=>[:show]
  prepend_before_filter :normalize_identifier, :only=>[:audit, :edit, :show, :update, :destroy] 
  
  def show
    @asset = ActiveFedora::Base.find(params["id"])
    opts = {}
    ds = nil
    opts[:filename] = params["filename"] || @asset.label
    opts[:disposition] = params["disposition"] if params.has_key?("disposition") 
    if params.has_key?(:datastream_id)
      opts[:filename] = params[:datastream_id]
      ds = @asset.datastreams[params[:datastream_id]]
    end
    ds = default_content_ds(@asset) if ds.nil?
    data = ds.content
    opts[:type] = ds.mimeType
    send_data data, opts
    return
  end
  
  private 
  
  def default_content_ds(asset)
    ActiveFedora::ContentModel.known_models_for(asset).each do |model_class|
      return model_class.default_content_ds if model_class.respond_to?(:default_content_ds)
    end
    if asset.datastreams.keys.include?(DownloadsController.default_content_dsid)
      return asset.datastreams[DownloadsController.default_content_dsid]
    else
      return asset.inner_object.profile.to_xml
    end
  end
  
  def self.default_content_dsid
    "content"
  end
  
  # Custom enforcement for show requests -- redirects to catalog_path if not reader.
  def deny_access_if_not_reader
    authenticate_user!
    load_permissions_from_solr
    unless can? :read, @permissions_solr_document
      redirect_to catalog_path
      return
    end
  end  
end
