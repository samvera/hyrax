# frozen_string_literal: true
module Hyrax::Matchers
  class MatchValkyrieIdsWithActiveFedoraIds < RSpec::Matchers::BuiltIn::ContainExactly
    def match_when_sorted?
      values_match?(safe_sort(expected), safe_sort(actual.map(&:id)))
    end
  end

  def match_valkyrie_ids_with_active_fedora_ids(expected_fedora_ids)
    MatchValkyrieIdsWithActiveFedoraIds.new(expected_fedora_ids)
  end
end
