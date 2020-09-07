# frozen_string_literal: true
class ExpireLeaseJob < Hyrax::ApplicationJob
  def perform(record)
    Hyrax::Actors::LeaseActor.new(record).destroy
  end
end
