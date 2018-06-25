class SingleUseLink < ActiveRecord::Base
  validate :expiration_date_cannot_be_in_the_past
  validate :cannot_be_destroyed

  alias_attribute :downloadKey, :download_key
  alias_attribute :itemId, :item_id

  after_initialize :set_defaults

  # rubocop:disable Naming/MethodName
  def downloadKey
    Deprecation.warn(self, 'The #downloadKey attribute is deprecated. Use #download_key instead.')
    download_key
  end

  def downloadKey=(val)
    Deprecation.warn(self, 'The #downloadKey attribute is deprecated. Use #download_key instead.')
    self.download_key = val
  end

  def itemId
    Deprecation.warn(self, 'The #itemId attribute is deprecated. Use #item_id instead.')
    item_id
  end

  def itemId=(val)
    Deprecation.warn(self, 'The #itemId attribute is deprecated. Use #item_id instead.')
    self.item_id = val
  end
  # rubocop:enable Naming/MethodName

  def create_for_path(path)
    self.class.create(item_id: item_id, path: path)
  end

  def expired?
    DateTime.current > expires
  end

  def to_param
    download_key
  end

  private

    def expiration_date_cannot_be_in_the_past
      errors.add(:expires, "can't be in the past") if expired?
    end

    def cannot_be_destroyed
      errors[:base] << "Single Use Link has already been used" if destroyed?
    end

    def set_defaults
      return unless new_record?
      self.expires ||= DateTime.current.advance(hours: 24)
      self.download_key ||= (Digest::SHA2.new << rand(1_000_000_000).to_s).to_s
    end
end
