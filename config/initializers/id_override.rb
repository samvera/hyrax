module ActiveFedora
  class UnsavedDigitalObject 
    def assign_pid
      @pid ||= PSU::IdService.mint
    end
  end
end
