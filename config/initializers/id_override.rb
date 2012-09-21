module ActiveFedora
  class UnsavedDigitalObject
    def assign_pid
      @pid ||= ScholarSphere::IdService.mint
    end
  end
end
