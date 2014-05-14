class SingleUseLink < ActiveRecord::Base

  validate :expiration_date_cannot_be_in_the_past
  validate :cannot_be_destroyed

  after_initialize :set_defaults

  def create_for_path path
    self.class.create itemId: itemId, path: path
  end

  def expired?
    DateTime.now > expires
  end


  def to_param
    downloadKey
  end

  protected

  def expiration_date_cannot_be_in_the_past
    if expired?
       errors.add(:expires, "can't be in the past")
    end
  end

  def cannot_be_destroyed
    if destroyed?
      errors[:base] << "Single Use Link has already been used"
    end
  end

  def set_defaults
    if new_record?
      self.expires ||= DateTime.now.advance(hours:24)
      self.downloadKey ||= (Digest::SHA2.new << rand(1000000000).to_s).to_s
    end
  end

end
