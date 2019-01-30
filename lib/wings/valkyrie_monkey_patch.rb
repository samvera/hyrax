if defined?(Valkyrie)

  # TODO: See https://github.com/samvera-labs/valkyrie/pull/654
  warning_message = "Monkey Patch Invalidated?\n\tIt appears that https://github.com/samvera-labs/valkyrie/pull/654 has been merged, look to the details of that PR to look to remove this monkey patch"
  raise(warning_message) if Valkyrie.config.respond_to?(:resource_class_resolver)

  require 'wings/resource_factory'

  module Valkyrie
    module MonkeyPatch
      module ResourceClassResolver
        def resource_klass
          Wings::ResourceFactory.convert_class_name_to_valkyrie_resource_class(internal_resource)
        end
      end
    end

    class Valkyrie::Persistence::Postgres::ORMConverter
      include Valkyrie::MonkeyPatch::ResourceClassResolver
    end
    class Valkyrie::Persistence::Solr::ORMConverter
      include Valkyrie::MonkeyPatch::ResourceClassResolver
    end
  end
end
