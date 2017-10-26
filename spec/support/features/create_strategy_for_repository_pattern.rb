# frozen_string_literal: true

# Factories in Factory Girl don't return the value returned via `to_create`.
# This custom strategy is necessary to enable data mapper patterns in Factory
# Girl.
#
# Copied from:
#   https://github.com/thoughtbot/factory_girl/issues/565
class CreateStrategyForRepositoryPattern
  def association(runner)
    runner.run
  end

  def result(evaluation)
    result = nil
    evaluation.object.tap do |instance|
      evaluation.notify(:after_build, instance)
      evaluation.notify(:before_create, instance)
      result = evaluation.create(instance)
      evaluation.notify(:after_create, result)
    end

    result
  end
end
FactoryBot.register_strategy(:create_for_repository, CreateStrategyForRepositoryPattern)
