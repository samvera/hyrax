class BatchEditsController < ApplicationController
   include Hydra::BatchEditBehavior
   include GenericFileHelper
   include Sufia::BatchEditsControllerBehavior
end
