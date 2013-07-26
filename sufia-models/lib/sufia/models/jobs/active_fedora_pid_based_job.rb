class ActiveFedoraPidBasedJob
  def queue_name
    :pid_based
  end

  attr_accessor :pid
  def initialize(pid)
    self.pid = pid
  end
  def object
    @object ||= ActiveFedora::Base.find(pid, cast:true)
  end
  alias_method :generic_file, :object
  alias_method :generic_file_id, :pid

  def run
    raise RuntimeError, "Define #run in a subclass"
  end
end