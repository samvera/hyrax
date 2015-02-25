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

      def create_file_from_item
        batch = Batch.create
        file_actor = Sufia::GenericFile::Actor.new(::GenericFile.new, user)
        file_actor.create_metadata(batch.id)
        store_checksum(file_actor.generic_file)
        file_actor.create_content(file, item['file']['filename'], file_path, item['file']['contentType'])
        BatchUpdateJob.new(user.user_key, batch.id, item['metadata']['title'], attributes, default_visibility).run
        file_actor.generic_file
      end

      def update_file_from_item(gf)
        file_actor = Sufia::GenericFile::Actor.new(gf, user)
        reset_metadata(file_actor)
        file_actor.update_metadata(attributes, default_visibility)
        store_checksum(file_actor.generic_file)
        file_actor.update_content(file, file_path)
        file_actor.generic_file
      end

      def destroy_file(gf)
        gf.destroy
      end

      private

        def reset_metadata(actor)
          actor.generic_file.tap do |gf|
            gf.resource_type = []
            gf.title = []
            gf.rights = []
            gf.tag = []
            gf.creator = []
            gf.description = []
            gf.publisher = []
            gf.date_created = []
            gf.based_near = []
            gf.identifier = []
            gf.related_url = []
            gf.language = []
            gf.contributor = []
          end
        end

        def store_checksum(gf)
          gf.arkivo_checksum = item['file']['md5']
        end

        def default_visibility
          'open'
        end

        def attributes
          Sufia::Arkivo::MetadataMunger.new(item['metadata']).call
        end

        def file_path
          'content'
        end

        def file
          extract_file_from_item
        end

        def extract_file_from_item
          encoded = item['file']['base64']
          content = Base64.decode64(encoded)
          tmp = Tempfile.new(item['file']['md5'], { encoding: Encoding::UTF_8 })
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
