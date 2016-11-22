module CurationConcerns
  class SingleUseLinkSearchBuilder < ::SearchBuilder
    include Sufia::SingleResult
    self.default_processor_chain = [:find_one]
  end
end
