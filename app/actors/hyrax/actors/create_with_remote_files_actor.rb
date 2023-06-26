# frozen_string_literal: true
module Hyrax
  module Actors
    # If there is a key +:remote_files+ in the attributes, it attaches the files at the specified URIs
    # to the work. e.g.:
    #     attributes[:remote_files] = filenames.map do |name|
    #       { url: "https://example.com/file/#{name}", file_name: name }
    #     end
    #
    # Browse everything may also return a local file. And although it's in the
    # url property, it may have spaces, and not be a valid URI.
    class CreateWithRemoteFilesActor < Hyrax::Actors::AbstractActor
      # @param [Hyrax::Actors::Environment] env
      # @return [Boolean] true if create was successful
      def create(env)
        remote_files = env.attributes.delete(:remote_files)
        next_actor.create(env) && attach_files(env, remote_files)
      end

      # @param [Hyrax::Actors::Environment] env
      # @return [Boolean] true if update was successful
      def update(env)
        remote_files = env.attributes.delete(:remote_files)
        next_actor.update(env) && attach_files(env, remote_files)
      end

      private

      def attach_files(env, remote_files)
        ingest_remote_files_service_class.new(user: env.user,
                                              curation_concern: env.curation_concern,
                                              remote_files: remote_files,
                                              file_set_actor_class: file_set_actor_class).attach!
      end

      class IngestRemoteFilesService
        ##
        # @parm user [User]
        # @parm curation_concern [Hyrax::Work]
        # @param remote_files [HashWithIndifferentAccess]
        # @param file_set_actor_class
        # @param ordered_members [Array]
        # @param ordered [Boolean]
        # rubocop:disable Metrics/ParameterLists
        def initialize(user:, curation_concern:, remote_files:, file_set_actor_class:, ordered_members: [], ordered: false)
          @remote_files = remote_files
          @user = user
          @curation_concern = curation_concern
          @file_set_actor_class = file_set_actor_class
          @ordered_members = ordered_members
          @ordered = ordered
        end
        # rubocop:enable Metrics/ParameterLists
        attr_reader :remote_files, :user, :curation_concern, :ordered_members, :ordered, :file_set_actor_class

        ##
        # @return true
        def attach!
          return true unless remote_files
          remote_files.each do |file_info|
            next if file_info.blank? || file_info[:url].blank?
            # Escape any space characters, so that this is a legal URI
            uri = URI.parse(Addressable::URI.escape(file_info[:url]))
            unless self.class.validate_remote_url(uri)
              Hyrax.logger.error "User #{user.user_key} attempted to ingest file from url #{file_info[:url]}, which doesn't pass validation"
              return false
            end
            auth_header = file_info.fetch(:auth_header, {})
            create_file_from_url(uri, file_info[:file_name], auth_header)
          end
          add_ordered_members! if ordered
          true
        end

        def self.registered_ingest_dirs
          Hyrax.config.registered_ingest_dirs
        end

        # @param uri [URI] the uri fo the resource to import
        def self.validate_remote_url(uri)
          if uri.scheme == 'file'
            path = File.absolute_path(CGI.unescape(uri.path))
            registered_ingest_dirs.any? do |dir|
              path.start_with?(dir) && path.length > dir.length
            end
          else
            Hyrax.logger.debug "Assuming #{uri.scheme} uri is valid without a serious attempt to validate: #{uri}"
            true
          end
        end

        private

        def create_file_from_url(uri, file_name, auth_header)
          import_url = URI.decode_www_form_component(uri.to_s)
          file_set = ::FileSet.new(import_url: import_url, label: file_name)

          __create_file_from_url(file_set: file_set, uri: uri, auth_header: auth_header)
        end

        def __create_file_from_url(file_set:, uri:, auth_header:)
          actor = file_set_actor_class.new(file_set, user)
          actor.create_metadata(visibility: curation_concern.visibility)
          actor.attach_to_work(curation_concern)
          file_set.save! if file_set.respond_to?(:save!)
          # We'll remember the order, but if it's not `@ordered` we won't do anything.
          ordered_members << file_set
          if uri.scheme == 'file'
            # Turn any %20 into spaces.
            file_path = CGI.unescape(uri.path)
            IngestLocalFileJob.perform_later(file_set, file_path, user)
          else
            ImportUrlJob.perform_later(file_set, operation_for(user: user), auth_header)
          end
        end

        def operation_for(user:)
          Hyrax::Operation.create!(user: user,
                                   operation_type: "Attach Remote File")
        end

        def add_ordered_members!
          actor = Hyrax::Actors::OrderedMembersActor.new(ordered_members, user)
          actor.attach_ordered_members_to_work(curation_concern)
        end
      end
      class_attribute :file_set_actor_class, default: ::Hyrax::Actors::FileSetActor
      class_attribute :ingest_remote_files_service_class, default: ::Hyrax::Actors::CreateWithRemoteFilesActor::IngestRemoteFilesService
    end
  end
end
