module CurationConcerns::WorkActorBehavior
  extend ActiveSupport::Concern
  extend Deprecation

  included do
    Deprecation.warn(CurationConcerns::WorkActorBehavior, "CurationConcerns::WorkActorBehavior is deprecated and will be removed in CurationConcerns 1.0")
  end
end
