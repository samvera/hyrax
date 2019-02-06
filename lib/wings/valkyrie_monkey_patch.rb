# frozen_string_literal: true

# ********************************************************************************
# BEGIN samvera-labs/valkyrie#659
# Ported fix from https://github.com/samvera-labs/valkyrie/pull/659/files
# ********************************************************************************
valkyrie_1_4_0_message = "Monkey Patch for AlternateID?\n"
valkyrie_1_4_0_message += "\tPlease check if https://github.com/samvera-labs/valkyrie/pull/659\n"
valkyrie_1_4_0_message += "\tIf it is merged, check to see if it is part of a released version of Valkyrie\n"
valkyrie_1_4_0_message += "\tIf so, you should be able to remove the following patch."
raise(valkyrie_1_4_0_message) unless Valkyrie::VERSION == "1.4.0"
module Valkyrie
  module MonkeyPatch
    module MemoryPatchToHandleNonExistentAlternateId
      def find_by_alternate_identifier(alternate_identifier:)
        alternate_identifier = Valkyrie::ID.new(alternate_identifier.to_s) if alternate_identifier.is_a?(String)
        validate_id(alternate_identifier)
        cache.select do |_key, resource|
          next unless resource[:alternate_ids]
          resource[:alternate_ids].include?(alternate_identifier)
        end.values.first || raise(::Valkyrie::Persistence::ObjectNotFoundError)
      end
    end
  end
end

# For some reason Valkyrie was clinging to a method definition, and the line below forces
# Valkyrie to remove the method and allow the expected include behavior to work.
# One thing is for sure, Valkyrie is tenanicious!
Valkyrie::Persistence::Memory::QueryService.send(:remove_method, :find_by_alternate_identifier)
Valkyrie::Persistence::Memory::QueryService.include(Valkyrie::MonkeyPatch::MemoryPatchToHandleNonExistentAlternateId)
# ********************************************************************************
# END samvera-labs/valkyrie#659
# ********************************************************************************
