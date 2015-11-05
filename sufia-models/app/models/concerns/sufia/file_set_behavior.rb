module Sufia
  module FileSetBehavior
    extend ActiveSupport::Concern
    include Sufia::FileSet::UploadSets
  end
end
