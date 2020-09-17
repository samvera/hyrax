# frozen_string_literal: true
class LeaseExpiryJob < Hyrax::ApplicationJob
  def perform
    records_with_expired_leases.each do |id|
      work = ActiveFedora::Base.find(id)
      Hyrax::Actors::LeaseActor.new(work).destroy
    end
  end

  ##
  # @return [Enumerator<String>] ids for all the objects that have expired active leases
  def records_with_expired_leases
    Hyrax::LeaseService.assets_with_expired_leases.map(&:id)
  end
end
