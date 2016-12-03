module Hyrax
  class BatchEditsController < ApplicationController
    include Hydra::BatchEditBehavior
    include FileSetHelper
    include BatchEditsControllerBehavior
  end
end
