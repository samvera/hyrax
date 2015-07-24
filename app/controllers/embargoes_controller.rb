class EmbargoesController < ApplicationController
  include CurationConcerns::ManagesEmbargoes
  include CurationConcerns::EmbargoesControllerBehavior
  include Hydra::Collections::AcceptsBatches
end
