class CopyPermissionsJob 
  def queue_name
    :permissions
  end

  attr_accessor :id

  def initialize(id)
    self.id = id
  end

  def run
    work = ActiveFedora::Base.load_instance_from_solr(id)
    if work.respond_to?(:generic_files)
      work.generic_files.each do |file|
        work.permissions.each {|perm| file.permissions << Hydra::AccessControls::Permission.new(perm.to_hash)}
      end
    end
  end
end
