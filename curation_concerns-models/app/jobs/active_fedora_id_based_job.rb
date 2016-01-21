class ActiveFedoraIdBasedJob < ActiveJob::Base
  queue_as :id_based

  attr_accessor :id

  def object
    @object ||= ActiveFedora::Base.find(id)
  end

  alias file_set object

  def perform(_)
    fail 'Define #run in a subclass'
  end
end
