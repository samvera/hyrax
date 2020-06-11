# frozen_string_literal: true
class SolrHit < Delegator
  def __getobj__
    @document # return object we are delegating to, required
  end

  alias static_config __getobj__

  def __setobj__(obj)
    @document = obj
  end

  attr_reader :document

  def initialize(document)
    document = document.with_indifferent_access
    super
    @document = document
  end

  def id
    document[Hyrax.config.id_field]
  end
end
