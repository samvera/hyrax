module RightsService
  extend Deprecation
  mattr_accessor :authority
  begin
    self.authority = Qa::Authorities::Local.subauthority_for('rights')
  rescue Qa::InvalidSubAuthority
    Deprecation.warn(RightsService, "You are using the deprecated RightsService module, but you do not have 'rights.yml'. Switch to CurationConcerns::LicenseService instead")
    self.authority = Qa::Authorities::Local.subauthority_for('licenses')
  end

  def self.select_all_options
    Deprecation.warn(RightsService, "RightsService is deprecated. Use CurationConcerns.config.license_service_class instead. This will be removed in curation_concerns 2.0")
    authority.all.map do |element|
      [element[:label], element[:id]]
    end
  end

  def self.select_active_options
    active_elements.map { |e| [e[:label], e[:id]] }
  end

  def self.active?(id)
    authority.find(id).fetch('active')
  end

  def self.label(id)
    authority.find(id).fetch('term')
  end

  def self.active_elements
    authority.all.select { |e| active?(e[:id]) }
  end
end
