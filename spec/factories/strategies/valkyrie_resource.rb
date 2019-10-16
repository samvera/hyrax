# This strategy is registered in spec_helper.rb and given a name that can be called by factory bot (e.g. create_using_hyrax_adapter).
# See spec_helper.rb to confirm registered name.
# Example:  let(:resource) { FactoryBot.create_using_hyrax_adapter(:hyrax_work) }
class ValkyrieHyraxAdapterCreateStrategy
  def result(evaluation)
    evaluation.notify(:after_build, evaluation.object)
    evaluation.notify(:before_create, evaluation.object)

    result = Hyrax.persister.save(resource: evaluation.object)

    evaluation.notify(:after_create, result)
    result
  end
end

# This strategy is registered in spec_helper.rb and given a name that can be called by factory bot (e.g. create_using_test_adapter).
# The test adapter is registered in spec_helper.rb (e.g. in-memory adapter).
# See spec_helper.rb to confirm registered name of the strategy and the test adapter registration.
# Example:  let(:resource) { FactoryBot.create_using_test_adapter(:hyrax_work) }
class ValkyrieTestAdapterCreateStrategy
  def result(evaluation)
    evaluation.notify(:after_build, evaluation.object)
    evaluation.notify(:before_create, evaluation.object)

    persister = Valkyrie::MetadataAdapter.find(:test_adapter).persister
    result = persister.save(resource: evaluation.object)

    evaluation.notify(:after_create, result)
    result
  end
end
