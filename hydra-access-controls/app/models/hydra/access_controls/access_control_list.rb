module Hydra::AccessControls
  class AccessControlList < ActiveFedora::Base
    belongs_to :access_to, predicate: ::ACL.accessTo, class_name: 'ActiveFedora::Base'
    property :mode, predicate: ::ACL.mode, class_name: 'Hydra::AccessControls::Mode'
    property :agent, predicate: ::ACL.agent, class_name: 'Hydra::AccessControls::Agent'
    # property :agentClass, predicate: ACL.agentClass

    # [acl:accessTo <card>; acl:mode acl:Read; acl:agentClass foaf:Agent].
    # [acl:accessTo <card>; acl:mode acl:Read, acl:Write;  acl:agent <card#i>].
  end

  class Mode < ActiveTriples::Resource
  end
  class Agent < ActiveTriples::Resource
  end
end
