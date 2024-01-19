# frozen_string_literal: true

module Hyrax
  ##
  # A Plain Old Ruby Object (PORO) representing a named group.
  #
  # In Hyku, we replace the PORO with an Application Record.  But there is significant duplication
  # of logic.
  #
  # @see Hyrax::GroupBehavior
  class Group
    include Hyrax::GroupBehavior

    def initialize(name)
      @name = name
    end

    attr_reader :name
  end
end
