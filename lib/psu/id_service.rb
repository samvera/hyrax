module PSU
  class IdService
    @@minter = Noid::Minter.new(:template => '.reeddeeddk')
    @@namespace = ScholarSphere::Application.config.id_namespace
    def self.valid?(identifier)
      # remove the fedora namespace since it's not part of the noid
      noid = identifier.split(":").last
      return @@minter.valid? noid
    end
    def self.mint
      taken = true
      while taken
        pid = self.next_id
        taken = ActiveFedora::Base.exists?(pid)
      end
      return pid
    end    
    protected
    def self.next_id
      return "#{@@namespace}:#{@@minter.mint}"
    end
  end
end
