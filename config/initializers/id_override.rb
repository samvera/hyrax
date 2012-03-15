module ActiveFedora
  class UnsavedDigitalObject 
    def assign_pid
      return @pid if @pid
      taken = true
      while taken
        @pid = PSU::IdService.mint
        taken = ActiveFedora::Base.exists?(@pid)
      end
      @pid
    end
  end
end
