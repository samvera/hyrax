# frozen_string_literal: true

module Hyrax
  module Forms
    class ChangeSetForm < WorkForm
      ##
      # @param [Valkyrie::Resource] model
      # @param [Hyrax::Ability] current_ability
      # @param [#params] controller
      def initialize(model, current_ability, *controller)
        @controller      = controller
        @current_ability = current_ability
        @model           = Hyrax::ChangeSet.for(model)
      end

      # @param [Symbol] key the field to read
      #
      # @return [Object] the value(s) of the form field
      def [](key)
        model.pubilc_send(key)
      end
    end
  end
end
