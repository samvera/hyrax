module CurationConcerns
  class CollectionMemberSearchBuilder < Hydra::Collections::MemberSearchBuilder
    include CurationConcerns::FilterByType
  end
end
