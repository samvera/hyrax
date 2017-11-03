require 'base64'
require 'tempfile'

# Ugly monkeypatch to make Tempfiles quack like UploadedFiles
Tempfile.class_eval do
  attr_accessor :original_filename, :content_type
end

module Hyrax
  module Arkivo
    class Actor
      attr_reader :user, :item
      class_attribute :work_change_set_persister, :file_set_change_set_persister,
                      :file_set_change_set_class
      self.work_change_set_persister = Hyrax::ChangeSetPersister.new(
        metadata_adapter: Valkyrie::MetadataAdapter.find(:indexing_persister),
        storage_adapter: Valkyrie.config.storage_adapter
      )
      self.file_set_change_set_persister = Hyrax::FileSetChangeSetPersister.new(
        metadata_adapter: Valkyrie::MetadataAdapter.find(:indexing_persister),
        storage_adapter: Valkyrie.config.storage_adapter
      )
      self.file_set_change_set_class = Hyrax::FileUploadChangeSet

      def initialize(user, item)
        @user = user
        @item = item
      end

      def work_change_set_class
        "#{work_type}ChangeSet".constantize
      end

      def work_type
        Hyrax.primary_work_type
      end

      def resource_params
        attributes.merge(arkivo_checksum: item['file']['md5'])
      end

      def create_work_from_item
        saved_work = create_work
        create_file_set(saved_work)
        saved_work
      end

      def update_work_from_item(work)
        update_work(work)
        update_file_set(find_file_set(work))
        work
      end

      def destroy_work(work)
        change_set = work_change_set_class.new(work)
        work_change_set_persister.buffer_into_index do |persist|
          persist.delete(change_set: change_set)
        end
      end

      private

        def find_file_set(work)
          Hyrax::Queries.find_members(resource: work, model: ::FileSet).first ||
            raise("Unable to find file set for #{work.id}")
        end

        class SearchContext
          def initialize(user)
            @user = user
          end
          attr_reader :user
        end

        def search_context
          SearchContext.new(user)
        end

        def create_work
          change_set = work_change_set_class.new(work_type.new)
          raise "Unable to create work. #{change_set.errors.messages}" unless change_set.validate(resource_params)
          change_set.sync
          saved_work = nil
          work_change_set_persister.buffer_into_index do |buffered_changeset_persister|
            saved_work = buffered_changeset_persister.save(change_set: change_set)
          end
          saved_work
        end

        def create_file_set(work)
          params = { label: item['file']['filename'],
                     files: [file],
                     search_context: search_context }
          change_set = file_set_change_set_class.new(::FileSet.new, append_id: work.id)
          raise "Unable to create file set. #{change_set.errors.messages}" unless change_set.validate(params)
          change_set.sync
          file_set_change_set_persister.buffer_into_index do |buffered_changeset_persister|
            _saved_file_set = buffered_changeset_persister.save(change_set: change_set)
          end
        end

        def update_work(work)
          change_set = work_change_set_class.new(work)
          work_attributes = default_attributes.merge(attributes).merge(arkivo_checksum: item['file']['md5'])
          raise "Unable to create work. #{change_set.errors.messages}" unless change_set.validate(work_attributes)
          change_set.sync
          saved_work = nil
          work_change_set_persister.buffer_into_index do |buffered_changeset_persister|
            saved_work = buffered_changeset_persister.save(change_set: change_set)
          end
        end

        def update_file_set(file_set)
          change_set = file_set_change_set_class.new(file_set)
          file_set_params = { files: [file],
                              search_context: search_context }
          raise "Unable to create file set. #{change_set.errors.messages}" unless change_set.validate(file_set_params)
          change_set.sync
          file_set_change_set_persister.buffer_into_index do |buffered_changeset_persister|
            _saved_file_set = buffered_changeset_persister.save(change_set: change_set)
          end
        end

        def current_ability
          @current_ability ||= ::Ability.new(user)
        end

        # @return [Hash<String, Array>] a list of properties to set on the work. Keys must be strings in order for them to correctly merge with the values from arkivo (in `@item`)
        # rubocop:disable Metrics/MethodLength
        def default_attributes
          {
            "resource_type" => [],
            "title" => [],
            "rights" => [],
            "keyword" => [],
            "creator" => [],
            "description" => [],
            "publisher" => [],
            "date_created" => [],
            "based_near" => [],
            "identifier" => [],
            "related_url" => [],
            "language" => [],
            "contributor" => []
          }
        end
        # rubocop:enable Metrics/MethodLength

        def default_visibility
          Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC
        end

        def attributes
          Hyrax::Arkivo::MetadataMunger.new(item['metadata']).call
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
