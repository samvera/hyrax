module ActiveFedora
  # = Active Fedora Persistence
  module Persistence
    #class UnsavedDigitalObject
    def assign_pid
      @pid ||= Sufia::IdService.mint
    end
  end
end