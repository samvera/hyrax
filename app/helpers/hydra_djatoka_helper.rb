module HydraDjatokaHelper
  
  def hydra_djatoka_url_for(document, opts={})
    
    if document.kind_of?(SolrDocument)
      pid = document.id
    elsif document.kind_of?(Mash) 
      pid = document[:id]
    elsif document.respond_to?(:pid)
        pid = document.pid
    end
    
    if !pid.nil?
      if opts[:scale]
        result = url_for(:controller=>:get,:action=>"show",:id=>pid, :format=>"jp2", "image_server[scale]"=>opts[:scale])
      else
        result = url_for(:controller=>:get,:action=>"show",:id=>pid, :format=>"jp2", "image_server"=>true)
      end
    end
      
  end
  
end