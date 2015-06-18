# Override this file locally if you want to define your own GenericWork class
class GenericWork < ActiveFedora::Base
  include ::CurationConcerns::GenericWorkBehavior
  include Sufia::GenericFile::Metadata
end
