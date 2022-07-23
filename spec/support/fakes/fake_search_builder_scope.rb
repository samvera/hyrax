# frozen_string_literal: true

##
# +Blacklight::SearchBuilder+ requires a 'scope' object, which its documentation
# describes as "the scope where the filter methods reside in."
#
# Often (usually?) this is a Controller with:
#   - +#blacklight_config+
#   - +#current_ability+
#   - +#current_user+
#   - +#params+
#   - +#repository+
#   - +#search_state_class+
#
# This provides a fake scope with more control than a generic RSpec double.
class FakeSearchBuilderScope
  ##
  # @!attribute [r] blacklight_config
  #   @return [Blacklight::Configuration]
  # @!attribute [r] current_ability
  #   @return [::Ability]
  # @!attribute [r] current_user
  #   @return [::User, nil]
  # @!attribute [r] params
  #   @return [Hash]
  # @!attribute [r] repository
  #   @return [Blacklight::AbstractRepository]
  # @!attribute [r] search_state_class
  #   @return [Blacklight::SearchState, nil]
  attr_reader :blacklight_config, :current_ability, :current_user, :params, :repository, :search_state_class

  ##
  # @param [Blacklight::Configuration] blacklight_config
  # @param [::Ability, nil] current_ability
  # @param [::User, nil] current_user
  def initialize(blacklight_config: CatalogController.blacklight_config, current_ability: nil, current_user: nil, params: {}, search_state_class: nil)
    @blacklight_config = blacklight_config
    @current_user = current_user
    @current_ability = current_ability || ::Ability.new(current_user)
    @params = params
    @repository = Blacklight::Solr::Repository.new(blacklight_config)
    @search_state_class = search_state_class
  end
end
