class ACL < RDF::StrictVocabulary('http://www.w3.org/ns/auth/acl#')
  property :accessTo
  property :mode
  property :agent
  property :agentClass
  property :accessControl

  property :Agent
  property :Read
  property :Write
  property :Append
  property :Control
end
