module ActiveFedora
  class UnsavedDigitalObject 
    def assign_pid
      return @pid if @pid
      unique = false
      until unique
        @pid = PSU::IdService.mint
        unique = ActiveFedora::Base.find(@pid).nil?
      end
      @pid
    end
  end
end
