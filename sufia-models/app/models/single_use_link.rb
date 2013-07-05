class SingleUseLink < ActiveRecord::Base

  attr_accessible :downloadKey, :expires, :itemId, :path if Rails::VERSION::MAJOR == 3
    
  
  def self.create_show(item_id)
     create_path(item_id, Sufia::Engine.routes.url_helpers.generic_file_path(item_id) )     
  end

  def self.create_download(item_id)
     create_path(item_id, Sufia::Engine.routes.url_helpers.download_path(item_id) )
  end
  
  def expired?
     now = DateTime.now
     return (now > expires)
  end
  
  protected
  def self.create_path(itemId, path)
     expires = DateTime.now.advance(hours:24)
     key = Digest::SHA2.new << rand(1000000000).to_s
     return create({downloadKey:key.to_s, expires:expires, path:path, itemId:itemId} )
  end
end
