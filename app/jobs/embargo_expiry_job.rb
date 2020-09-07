class EmbargoExpiryJob < Hyrax::ActiveJob

  def perform
    get_records_with_expired_embargos.each do |record|
      ExpireEmbargoJob.perform_later(record)
    end
  end

  def get_records_with_expired_embargos
    ids = Hyrax::EmbargoService.assets_with_expired_embargoes.map(&:id)
    works = ids.map {|id| ActiveFedora::Base.find(id)}
  end
end
