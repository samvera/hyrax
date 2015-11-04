module Sufia
  module FileSetBehavior
    extend ActiveSupport::Concern
    include Sufia::FileSet::Batches
  end
end
