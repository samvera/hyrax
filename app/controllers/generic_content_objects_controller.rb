class GenericContentObjectsController < ApplicationController
  
  include Hydra::AssetsControllerHelper
  include Hydra::FileAssetsHelper  
  include Hydra::RepositoryController  
  include MediaShelf::ActiveFedoraHelper
  include Blacklight::SolrHelper
  
  before_filter :require_fedora
  before_filter :require_solr


  def create 
    unless params.has_key?(:Filedata)
      raise "No file to process"
    end
    if !params[:container_id].nil? && params[:Filedata]
      af_base =  ActiveFedora::Base.find(params[:container_id])
      af_model = retrieve_af_model( af_base.relationships[:self][:has_model].first.split(":")[-1] )
      logger.debug "#########: af_model = #{af_model.to_s}"
      generic_content_object = af_model.load_instance(params[:container_id])
      generic_content_object.content={:file => params[:Filedata], :file_name => params[:Filename]}
      logger.debug "#########: set the content"
      generic_content_object.save
      logger.debug "#########: saved #{generic_content_object.pid} with new content #{params[:Filename]}"
      if af_model == GenericImage
        logger.debug "#########: deriving images"
        generic_content_object.derive_all
        logger.debug "#########: finished deriving images"
      end   
    end
    render :nothing => true
  end
  
  private
  
  
end