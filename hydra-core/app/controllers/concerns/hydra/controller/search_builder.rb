module Hydra::Controller::SearchBuilder
  extend ActiveSupport::Concern

  # Override blacklight to produce a search_builder that has the current ability in context
  def search_builder processor_chain = search_params_logic
    super.tap { |builder| builder.current_ability = current_ability }
  end

end
