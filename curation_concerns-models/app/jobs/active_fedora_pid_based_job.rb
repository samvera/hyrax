class ActiveFedoraPidBasedJob < ActiveFedoraIdBasedJob
  extend Deprecation
  def self.extended(document)
    Deprecation.warn ActiveFedoraPidBasedJob, "ActiveFedoraPidBasedJob is deprecated; use ActiveFedoraIdBasedJob instead."
  end
end
