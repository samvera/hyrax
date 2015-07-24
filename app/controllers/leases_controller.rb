class LeasesController < ApplicationController
  include CurationConcerns::ManagesEmbargoes
  include CurationConcerns::LeasesControllerBehavior
  include Hydra::Collections::AcceptsBatches
end
