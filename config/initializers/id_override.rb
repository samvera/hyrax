module ActiveFedora
  class UnsavedDigitalObject 
    def assign_pid
      return @pid if @pid
      bound = false
      until bound
        @pid = PSU::IdService.mint
        bound = ActiveFedora::Base.find(@pid).new_object?
      end
      @pid
    end
  end
end
