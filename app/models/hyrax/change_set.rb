# frozen_string_literal: true

module Hyrax
  ##
  # @api private
  #
  # Build a changeset class for the given resource class. The ChangeSet will
  # have fields to match the resource class given.
  #
  # @example
  #   Hyrax::ChangeSet(Monograph)
  def self.ChangeSet(resource_class)
    Class.new(Hyrax::ChangeSet) do
      (resource_class.fields - resource_class.reserved_attributes).each do |field|
        property field, default: nil
      end
    end
  end

  class ChangeSet < Valkyrie::ChangeSet
    ##
    # @api public
    #
    # Factory for resource ChangeSets
    #
    # @example
    #   monograph  = Monograph.new
    #   change_set = Hyrax::ChangeSet.for(monograph)
    #
    #   change_set.title = 'comet in moominland'
    #   change_set.sync
    #   monograph.title # => 'comet in moominland'
    #
    def self.for(resource)
      Hyrax::ChangeSet(resource.class).new(resource)
    end
  end
end
