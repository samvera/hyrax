# Override this file locally if you want to define your own GenericWork class
class GenericFile < ActiveFedora::Base
  include ::CurationConcerns::GenericFileBehavior
  # include Sufia::GenericFile::Metadata
end