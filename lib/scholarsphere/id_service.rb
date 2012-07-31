module ScholarSphere
  class IdService
    @@minter = Noid::Minter.new(:template => '.reeddeeddk')
    @@namespace = ScholarSphere::Application.config.id_namespace
    def self.valid?(identifier)
      # remove the fedora namespace since it's not part of the noid
      noid = identifier.split(":").last
      return @@minter.valid? noid
    end
    def self.mint
      while true
        pid = self.next_id
        break unless ActiveFedora::Base.exists?(pid)
      end
      return pid
    end
    protected
    def self.next_id
      # seed with process id so that if two processes are running they do not come up with the same id.
      @@minter.seed($$)
      return  "#{@@namespace}:#{@@minter.mint}"
    end
  end
end
