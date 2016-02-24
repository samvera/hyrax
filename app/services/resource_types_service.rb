module ResourceTypesService
  mattr_accessor :authority
  self.authority = Qa::Authorities::Local.subauthority_for('resource_types')

  def self.select_options
    authority.all.map do |element|
      [element[:label], element[:id]]
    end
  end

  def self.label(id)
    authority.find(id).fetch('term')
  end

  # @param [String] id identifier of the resource type
  def self.microdata_type(id)
    I18n.t("curation_concerns.schema_org.resource_type.#{id}",
           default: CurationConcerns.config.microdata_default_type)
  end
end
