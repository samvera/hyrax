module CurationConcerns
  class CollectionMemberSearchBuilder < CurationConcerns::MemberSearchBuilder
    include Sufia::FilterByType
  end
end
