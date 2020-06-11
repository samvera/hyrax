# frozen_string_literal: true
module Hyrax
  class SingleAdminSetSearchBuilder < Hyrax::AdminSetSearchBuilder
    include Hyrax::SingleResult

    # @param [#repository,#blacklight_config,#current_ability] context
    # @param access [Symbol] either :read or :edit access level to filter for
    def initialize(context, access = :read)
      super(context, access)
    end
  end
end
