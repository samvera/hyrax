class EmbargoExpiryJob < Hyrax::ApplicationJob

  def perform(record)
    Hyrax::Actors::EmbargoActor.new(record).destroy
  end

end
