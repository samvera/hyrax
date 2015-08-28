class ActiveFedoraIdBasedJob < ActiveJob::Base
  queue_as :id_based

  attr_accessor :id

  def object
    @object ||= ActiveFedora::Base.find(id)
  end

  alias_method :generic_file, :object

  def perform(_)
    fail 'Define #run in a subclass'
  end
end
