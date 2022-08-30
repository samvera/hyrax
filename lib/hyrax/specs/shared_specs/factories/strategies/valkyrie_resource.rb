# frozen_string_literal: true
# @see https://github.com/thoughtbot/factory_bot/blob/master/GETTING_STARTED.md#custom-strategies
# @example
#   let(:resource) { FactoryBot.valkyrie_create(:hyrax_work) }
class ValkyrieCreateStrategy
  def initialize
    @strategy = FactoryBot.strategy_by_name(:create).new
  end

  delegate :association, to: :@strategy

  def result(evaluation)
    evaluation.notify(:after_build, evaluation.object)
    evaluation.notify(:before_create, evaluation.object)

    result = persister.save(resource: evaluation.object)

    evaluation.notify(:after_create, result)
    result
  end

  def to_sym
    :valkyrie_create
  end

  private

  def persister
    Hyrax.persister
  end
end
