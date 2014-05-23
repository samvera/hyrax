module Worthwhile
  module AbilityHelper
    # Returns true if can create at least one type of work
    def can_ever_create_works?
      can = false
      Worthwhile.configuration.curation_concerns.each do |curation_concern_type|
        break if can
        can = can?(:create,curation_concern_type)
      end
      return can
    end
  end
end