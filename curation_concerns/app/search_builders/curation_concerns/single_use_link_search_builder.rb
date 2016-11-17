module CurationConcerns
  class SingleUseLinkSearchBuilder < ::SearchBuilder
    include CurationConcerns::SingleResult
    self.default_processor_chain = [:find_one]
  end
end
