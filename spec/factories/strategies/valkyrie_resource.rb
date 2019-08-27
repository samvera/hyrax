class ValkyrieCreateStrategy
  def result(evaluation)
    evaluation.notify(:after_build, evaluation.object)
    evaluation.notify(:before_create, evaluation.object)

    result = Hyrax.persister.save(resource: evaluation.object)

    evaluation.notify(:after_create, result)
    result
  end
end
