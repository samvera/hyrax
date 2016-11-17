module CurationConcerns
  class CollectionMemberSearchBuilder < CurationConcerns::MemberSearchBuilder
    include CurationConcerns::FilterByType
  end
end
