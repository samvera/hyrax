# frozen_string_literal: true
class FakeAuthority
  def initialize(map)
    @map = map
  end

  def all
    @map
  end

  def find(id)
    @map.detect { |item| item[:id] == id }
  end
end
