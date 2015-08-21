module CurationConcerns
  class GenericFilesController < ApplicationController
    include CurationConcerns::GenericFilesControllerBehavior

    def generic_file_params
      params.require(:generic_file).permit! if params.key?(:generic_file)
    end
  end
end
