require 'base64'
require 'tempfile'

# Ugly monkeypatch to make Tempfiles quack like UploadedFiles
Tempfile.class_eval do
  attr_accessor :original_filename, :content_type
end

module Sufia
  module Arkivo
    class Actor
      attr_reader :user, :item

      def initialize(user, item)
        @user = user
        @item = item
      end

      def create_work_from_item
        upload_set = UploadSet.create
        work = ::GenericWork.new
        work_actor = CurationConcerns::GenericWorkActor.new(work, user, attributes.merge(arkivo_checksum: item['file']['md5']))
        raise "Unable to create work. #{work.errors.messages}" unless work_actor.create

        file_set = ::FileSet.new

        file_actor = ::CurationConcerns::FileSetActor.new(file_set, user)
        file_actor.create_metadata(upload_set.id, work)
        file_set.label = item['file']['filename']
        file_actor.create_content(file) # item['file']['contentType']
        UploadSetUpdateJob.perform_later(user.user_key, upload_set.id, item['metadata']['title'], attributes, default_visibility)
        work
      end

      def update_work_from_item(work)
        reset_metadata(work)
        work_actor = CurationConcerns::GenericWorkActor.new(work, user, attributes.merge(arkivo_checksum: item['file']['md5']))
        work_actor.update
        file_set = work.file_sets.first
        file_actor = ::CurationConcerns::FileSetActor.new(file_set, user)
        file_actor.update_content(file)
        work
      end

      def destroy_work(work)
        work.destroy
      end

      private

        def reset_metadata(work)
          work.resource_type = []
          work.title = []
          work.rights = []
          work.tag = []
          work.creator = []
          work.description = []
          work.publisher = []
          work.date_created = []
          work.based_near = []
          work.identifier = []
          work.related_url = []
          work.language = []
          work.contributor = []
        end

        def default_visibility
          'open'
        end

        def attributes
          Sufia::Arkivo::MetadataMunger.new(item['metadata']).call
        end

        def file
          extract_file_from_item
        end

        def extract_file_from_item
          encoded = item['file']['base64']
          content = Base64.decode64(encoded)
          tmp = Tempfile.new(item['file']['md5'], encoding: Encoding::UTF_8)
          tmp.binmode
          tmp.original_filename = item['file']['filename']
          tmp.content_type = item['file']['contentType']
          tmp.write(content)
          tmp.rewind
          tmp
        end
    end
  end
end
