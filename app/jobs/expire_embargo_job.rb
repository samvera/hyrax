# frozen_string_literal: true
class ExpireEmbargoJob < Hyrax::ApplicationJob
  def perform(record)
    Hyrax::Actors::EmbargoActor.new(record).destroy
  end
end
