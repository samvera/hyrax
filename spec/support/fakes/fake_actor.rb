# frozen_string_literal: true
class FakeActor < Hyrax::Actors::AbstractActor
  attr_accessor :created, :destroyed, :updated

  def create(env)
    self.created = env

    true
  end

  def destroy(env)
    self.destroyed = env

    true
  end

  def update(env)
    self.updated = env

    true
  end
end
