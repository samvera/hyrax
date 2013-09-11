class SingleUseLink < ActiveRecord::Base

  deprecated_attr_accessible :downloadKey, :path, :expires, :itemId
    
  after_initialize :set_defaults

  def create_for_path path
    self.class.create :itemId => itemId, :path => path
  end

  def expired?
    DateTime.now > expires
  end

  protected
  def set_defaults
    if new_record?
      self.expires ||= DateTime.now.advance(hours:24)
      self.downloadKey ||= (Digest::SHA2.new << rand(1000000000).to_s).to_s
    end
  end

end