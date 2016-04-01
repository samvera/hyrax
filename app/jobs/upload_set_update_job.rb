class UploadSetUpdateJob < ActiveJob::Base
  include Hydra::PermissionsQuery
  include CurationConcerns::Messages

  queue_as :upload_set_update

  attr_accessor :saved, :denied

  # This copies metadata from the passed in attribute to all of the works that
  # are members of the given upload set
  def perform(user, upload_set, titles, attributes, visibility)
    @saved = []
    @denied = []

    titles ||= {}
    attributes = attributes.merge(visibility: visibility)

    update(user, upload_set, titles, attributes)
    send_user_message(user, upload_set)
  end

  private

    def update(user, upload_set, titles, attributes)
      upload_set.works.each do |work|
        title = titles[work.id] if titles[work.id]
        next unless update_work(user, work, title, attributes)
        # TODO: stop assuming that files only belong to one work
        saved << work
      end

      upload_set.update(status: ["Complete"])
    end

    def send_user_success_message(user, upload_set)
      return unless CurationConcerns.config.callback.set?(:after_upload_set_update_success)
      CurationConcerns.config.callback.run(:after_upload_set_update_success, user, upload_set)
    end

    def send_user_failure_message(user, upload_set)
      return unless CurationConcerns.config.callback.set?(:after_upload_set_update_failure)
      CurationConcerns.config.callback.run(:after_upload_set_update_failure, user, upload_set)
    end

    def send_user_message(user, upload_set)
      if denied.empty?
        send_user_success_message(user, upload_set) unless saved.empty?
      else
        send_user_failure_message(user, upload_set)
      end
    end

    def update_work(user, work, title, attributes)
      unless user.can? :edit, work
        ActiveFedora::Base.logger.error "User #{user.user_key} DENIED access to #{work.id}!"
        denied << work
        return
      end

      work.title = title if title
      work_actor(work, user).update(attributes)
    end

    def work_actor(work, user)
      CurationConcerns::CurationConcern.actor(work, user)
    end
end
