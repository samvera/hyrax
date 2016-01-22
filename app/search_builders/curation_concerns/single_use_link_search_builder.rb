module CurationConcerns
  class SingleUseLinkSearchBuilder < CurationConcerns::SearchBuilder
    include CurationConcerns::SingleResult
    self.default_processor_chain = [:find_one]
  end
end
