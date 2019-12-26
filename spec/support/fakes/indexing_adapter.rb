class FakeIndexingAdapter
  attr_reader :saved_resources

  def initialize
    @saved_resources = []
  end

  def save(resource:)
    @saved_resources << resource
  end
end
