# frozen_string_literal: true
class EmbargoExpiryJob < Hyrax::ApplicationJob
  def perform
    records_with_expired_embargos.each do |id|
      work = ActiveFedora::Base.find(id)
      Hyrax::Actors::EmbargoActor.new(work).destroy
    end
  end

  ##
  # @return [Enumerator<String>] ids for all the objects that have expired active embargoes
  def records_with_expired_embargos
    Hyrax::EmbargoService.assets_with_expired_embargoes.map(&:id)
  end
end
