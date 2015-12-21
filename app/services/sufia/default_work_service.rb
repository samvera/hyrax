module Sufia
  class DefaultWorkService
    def self.create(upload_set_id, title, user)
      # Ensure the upload set exists, before trying to associate a work with it.
      upload_set = UploadSet.find_or_create(upload_set_id)
      GenericWork.create!(title: [title], upload_set: upload_set) do |w|
        w.apply_depositor_metadata(user)
        w.date_uploaded = CurationConcerns::TimeService.time_in_utc
      end
    end
  end
end
