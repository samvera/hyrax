class SingleUseLink < ActiveRecord::Base

  attr_accessible :downloadKey, :expires, :itemId, :path

    
  
  def self.create_show(item_id)
     create_path(item_id, Rails.application.routes.url_helpers.generic_file_path(item_id) )     
  end

  def self.create_download(item_id)
     create_path(item_id, Rails.application.routes.url_helpers.download_path(item_id) )
  end
  
  def expired?
     now = DateTime.now
     return (now > expires)
  end
  
  protected
  def self.create_path(itemId, path)
     expires = DateTime.now.advance(hours:24)
     key = Digest::SHA2.new << DateTime.now.to_f.to_s      
     return create({downloadKey:key.to_s, expires:expires, path:path, itemId:itemId} )
  end
end
