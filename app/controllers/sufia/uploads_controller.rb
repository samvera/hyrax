class Sufia::UploadsController < ApplicationController
  before_action :authenticate_user!

  def create
    @uploaded_file = UploadedFile.create!(file: params[:files].first,
                                          user: current_user)
  end
end
