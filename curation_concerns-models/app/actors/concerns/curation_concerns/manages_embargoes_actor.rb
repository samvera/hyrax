module CurationConcerns
  #  To use this module, include it in your Actor class
  #  and then add its interpreters wherever you want them to run.
  #  They should be called _before_ apply_attributes is called because
  #  they intercept values in the attributes Hash.
  #
  #  @example
  #  class MyActorClass < BaseActor
  #     include Worthwile::ManagesEmbargoesActor
  #
  #     def create
  #       interpret_visibility && super
  #     end
  #
  #     def update
  #       interpret_visibility && super
  #     end
  #  end
  #
  module ManagesEmbargoesActor
    extend ActiveSupport::Concern
    extend Deprecation

    included do
      Deprecation.warn(ManagesEmbargoesActor, "ManagesEmbargoesActor is deprecated and will be removed in CurationConcerns 1.0")
    end
  end
end
