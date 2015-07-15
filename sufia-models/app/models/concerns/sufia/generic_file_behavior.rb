module Sufia
  module GenericFileBehavior
    extend ActiveSupport::Concern
    include Sufia::GenericFile::Batches
  end
end
