# Override this file locally if you want to define your own GenericFile class
class GenericFile < ActiveFedora::Base
  include ::CurationConcerns::GenericFileBehavior
end
