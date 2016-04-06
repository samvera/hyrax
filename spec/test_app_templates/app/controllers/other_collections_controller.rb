class OtherCollectionsController < ApplicationController
  include CurationConcerns::CollectionsControllerBehavior

  def show
    super
    redirect_to root_path
  end
end
