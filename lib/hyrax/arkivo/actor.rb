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
      class_attribute :change_set_persister
      self.change_set_persister = Hyrax::ChangeSetPersister.new(
        metadata_adapter: Valkyrie::MetadataAdapter.find(:indexing_persister),
        storage_adapter: Valkyrie.config.storage_adapter
      )
      def initialize(user, item)
        @user = user
        @item = item
      end

      def create_work_from_item
        change_set = build_change_set(Hyrax.primary_work_type.new)
        create_attrs = attributes.merge(arkivo_checksum: item['file']['md5'])
        raise "Unable to create work. #{work.errors.messages}" unless change_set.validate(create_attrs)
        file_set = create_file_set
        raise "Unable to create work. #{work.errors.messages}" unless change_set.validate(create_attrs.merge(member_ids: [file_set.id]))
        change_set.sync
        work = nil
        change_set_persister.buffer_into_index do |buffered_changeset_persister|
          work = buffered_changeset_persister.save(change_set: change_set)
        end
        work
      end

      def create_file_set
        file_set = ::FileSet.new

        file_actor = ::Hyrax::Actors::FileSetActor.new(file_set, user)
        file_actor.create_metadata
        file_set.label = item['file']['filename']
        file_actor.create_content(file) # item['file']['contentType']
        file_set
      end

      def build_change_set(work)
        DynamicChangeSet.new(work, ability: current_ability)
      end

      def update_work_from_item(work)
        change_set = build_change_set(work)

        work_attributes = default_attributes.merge(attributes).merge(arkivo_checksum: item['file']['md5'])

        change_set.validate(work_attributes)
        change_set.sync
        updated = nil
        change_set_persister.buffer_into_index do |persist|
          updated = persist.save(change_set: change_set)
        end

        file_set = Hyrax::Queries.find_members(resource: work, model: FileSet).first
        file_actor = ::Hyrax::Actors::FileSetActor.new(file_set, user)
        file_actor.update_content(file)
        updated
      end

      def destroy_work(work)
        work.destroy
      end

      private

        def current_ability
          @current_ability ||= ::Ability.new(user)
        end

        # @return [Hash<String, Array>] a list of properties to set on the work. Keys must be strings in order for them to correctly merge with the values from arkivio (in `@item`)
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
