# frozen_string_literal: true
module Hyrax
  module Forms
    ##
    # Nested form for embargos.
    class Embargo < Hyrax::ChangeSet
      property :visibility_after_embargo
      property :visibility_during_embargo
      property :embargo_release_date
      property :embargo_history, default: []
    end
  end
end
