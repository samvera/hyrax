require 'wings/active_fedora_converter'

module Wings
  module PcdmValkyrieBehavior
    ##
    # Gives the subset of #members that are PCDM objects
    # @return [Enumerable<PCDM::ObjectBehavior>] an enumerable over the members
    #   that are PCDM objects
    def objects(valkyrie: false)
      af_objects = Wings::ActiveFedoraConverter.new(resource: self).convert.objects
      return af_objects unless valkyrie
      af_objects.map(&:valkyrie_resource)
    end
  end
end
