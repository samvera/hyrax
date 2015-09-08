module CurationConcerns
  class GenericFilesController < ApplicationController
    include CurationConcerns::GenericFilesControllerBehavior

    def generic_file_params
      params.require(:generic_file).permit(
        :visibility_during_embargo, :embargo_release_date, :visibility_after_embargo, :visibility_during_lease, :lease_expiration_date, :visibility_after_lease, :visibility, title: [])
    end
  end
end
