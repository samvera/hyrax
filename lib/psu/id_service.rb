module PSU
  class IdService
    @@minter = Noid::Minter.new(:template => '.reeddeeddk')
    @@namespace = Rails.application.config.id_namespace
    def self.valid?(identifier)
      # remove the fedora namespace since it's not part of the noid
      noid = identifier.split(":").last
      @@minter.valid? noid
    end
    def self.mint
      "#{@@namespace}:#{@@minter.mint}"
    end    
  end
end
