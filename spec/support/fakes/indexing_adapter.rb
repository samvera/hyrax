# frozen_string_literal: true
class FakeIndexingAdapter
  attr_reader :deleted_resources, :saved_resources

  def initialize
    @deleted_resources = []
    @saved_resources = []
  end

  def save(resource:)
    @saved_resources << resource
  end

  def delete(resource:)
    @deleted_resources << resource
  end
end
