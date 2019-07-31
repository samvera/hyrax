module RSpec
  module Matchers
    module BuiltIn
      class MatchValkyrieIdsWithActiveFedoraIds < RSpec::Matchers::BuiltIn::ContainExactly
        def match_when_sorted?
          values_match?(safe_sort(expected), safe_sort(actual.map(&:id)))
        end
      end
    end
  end
end

module RSpec
  module Matchers
    def match_valkyrie_ids_with_active_fedora_ids(items)
      BuiltIn::MatchValkyrieIdsWithActiveFedoraIds.new(items)
    end
  end
end
