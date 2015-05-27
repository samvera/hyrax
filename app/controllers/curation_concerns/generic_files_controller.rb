module CurationConcerns
  class GenericFilesController < ApplicationController
    include CurationConcerns::FilesController

    def generic_file_params
      if params.has_key?(:generic_file)
        params.require(:generic_file).permit!
      end
    end

  end
end

