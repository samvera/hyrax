module Worthwhile
  module CurationConcern

    module_function
    
    def mint_a_pid
      Sufia::Noid.noidify(Sufia::IdService.mint)
    end  

    def actor(curation_concern, *args)
      actor_identifier = curation_concern.class.to_s.split('::').last
      klass = "CurationConcern::#{actor_identifier}Actor".constantize
      klass.new(curation_concern, *args)
    end
    
    def attach_file(generic_file, user, file_to_attach)
      Sufia::GenericFile::Actor.new(generic_file, user).create_content(file_to_attach, file_to_attach.original_filename, 'content')
    end
    
  end
end
