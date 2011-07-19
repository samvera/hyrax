module Hydra

  class Fixtures
    def self.filename_for_pid(pid)
      File.join("test_support","fixtures","#{pid.gsub(":","_")}.foxml.xml")
    end

    def self.delete(pid)
      begin
        ActiveFedora::Base.load_instance(pid).delete
        1
      rescue ActiveFedora::ObjectNotFoundError
        logger.debug "The object #{pid} has already been deleted (or was never created)."
        0
      end
    end

    def self.reload(pid)
      delete(pid)
      import_and_index(pid)
    end

    def self.import_and_index(pid)
      body = import_to_fedora(filename_for_pid(pid))
      index(pid)
      body
    end

    def self.index(pid)
        solrizer = Solrizer::Fedora::Solrizer.new 
        solrizer.solrize(pid) 
    end

    def self.import_to_fedora(filename)
      file = File.new(filename, "r")
puts "Loading #{filename}"
      result = foxml = Fedora::Repository.instance.ingest(file.read)
      raise "Failed to ingest the fixture." unless result
      result.body
    end
  end

end
