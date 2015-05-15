class CopyPermissionsJob 
  def queue_name
    :permissions
  end

  attr_accessor :id

  def initialize(id)
    self.id = id
  end

  def run
    # work = ActiveFedora::Base.load_instance_from_solr(id)
    work = ActiveFedora::Base.find(id)  # Hydra::Works::GenericWork is not compatible with load_instance_from_solr.  Using (slower) ActiveFedora::Base.find instead.
    if work.respond_to?(:generic_files)
      work.generic_files.each do |file|

        work.permissions.each {|perm| file.permissions << Hydra::AccessControls::Permission.new(perm.to_hash)}
        new_permissions = file.permissions.uniq! { |item| item.to_hash}
        file.permissions = new_permissions unless new_permissions.blank?
      end
    end
  end
end
