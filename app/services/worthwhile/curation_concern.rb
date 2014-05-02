module Worthwhile
  module CurationConcern

    module_function
    def mint_a_pid
      Sufia::Noid.namespaceize(Sufia::Noid.noidify(Sufia::IdService.mint))
    end

    def actor(curation_concern, *args)
      actor_identifier = curation_concern.class.to_s.split('::').last
      klass = Worthwhile::CurationConcern.const_get "#{actor_identifier}Actor"
      klass.new(curation_concern, *args)
    end
  end
end
