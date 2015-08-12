class SingleUseLink < ActiveRecord::Base
  validate :expiration_date_cannot_be_in_the_past
  validate :cannot_be_destroyed

  after_initialize :set_defaults

  def create_for_path(path)
    self.class.create(itemId: itemId, path: path)
  end

  def expired?
    DateTime.now > expires
  end

  def to_param
    downloadKey
  end

  protected

    def expiration_date_cannot_be_in_the_past
      errors.add(:expires, "can't be in the past") if expired?
    end

    def cannot_be_destroyed
      errors[:base] << "Single Use Link has already been used" if destroyed?
    end

    def set_defaults
      return unless new_record?
      self.expires ||= DateTime.now.advance(hours: 24)
      self.downloadKey ||= (Digest::SHA2.new << rand(1_000_000_000).to_s).to_s
    end
end
