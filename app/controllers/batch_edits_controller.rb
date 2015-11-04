class BatchEditsController < ApplicationController
  include Hydra::BatchEditBehavior
  include FileSetHelper
  include Sufia::BatchEditsControllerBehavior
end
