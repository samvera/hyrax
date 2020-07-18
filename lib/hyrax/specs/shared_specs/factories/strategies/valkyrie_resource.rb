# frozen_string_literal: true
# @see https://github.com/thoughtbot/factory_bot/blob/master/GETTING_STARTED.md#custom-strategies
# @example
#   let(:resource) { FactoryBot.valkyrie_create(:hyrax_work) }
class ValkyrieCreateStrategy
  def result(evaluation)
    evaluation.notify(:after_build, evaluation.object)
    evaluation.notify(:before_create, evaluation.object)

    result = persister.save(resource: evaluation.object)

    evaluation.notify(:after_create, result)
    query_service.find_by(id: result.id)
  end

  private

  def persister
    Hyrax.persister
  end

  def query_service
    Hyrax.query_service
  end
end

# @see https://github.com/thoughtbot/factory_bot/blob/master/GETTING_STARTED.md#custom-strategies
# @example
#   let(:resource) { FactoryBot.create_using_test_adapter(:hyrax_work) }
class ValkyrieTestAdapterCreateStrategy < ValkyrieCreateStrategy
  private

  def persister
    Valkyrie::MetadataAdapter.find(:test_adapter).persister
  end

  def query_service
    Valkyrie::MetadataAdapter.find(:test_adapter).query_service
  end
end
