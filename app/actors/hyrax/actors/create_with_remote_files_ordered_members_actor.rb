# frozen_string_literal: true
module Hyrax
  module Actors
    ##
    # When adding member {FileSetBehavior}s to a {WorkBehavior}, {Hyrax} saves
    # and reloads the work for each new member FileSet. This can significantly
    # slow down ingest for Works with many member FileSets. The saving and
    # reloading happens in {FileSetActor#attach_to_work}.
    #
    # This is a 'swappable' alternative approach. It will be of most value to
    # Hyrax applications dealing with works with many filesets. Anecdotally, a
    # 600 FileSet work can be processed in ~15 mins versus >3 hours with the
    # standard approach.
    #
    # The tradeoff is that the ordered members are now added in a single step
    # after the creation of all the FileSets, thus introducing a slight risk of
    # orphan filesets if the upload fails before the addition of the ordered members.
    # This has not been observed in practice.
    #
    # Swapping out the actors can be achieved thus:
    #
    # In +config/initializers/hyrax.rb+:
    #   Hyrax::CurationConcern.actor_factory.swap(Hyrax::Actors::CreateWithRemoteFilesActor,
    #     Hyrax::Actors::CreateWithRemoteFilesOrderedMembersActor)
    #
    # Alternatively, in +config/application.rb+:
    #  config.to_prepare
    #    Hyrax::CurationConcern.actor_factory.swap(Hyrax::Actors::CreateWithRemoteFilesActor,
    #      Hyrax::Actors::CreateWithRemoteFilesOrderedMembersActor)
    #  end
    #
    # If there is a key +:remote_files+ in the attributes, it attaches the files at
    # the specified URIs to the work. e.g.:
    #     attributes[:remote_files] = filenames.map do |name|
    #       { url: "https://example.com/file/#{name}", file_name: name }
    #     end
    #
    # Browse everything may also return a local file. And although it's in the
    # url property, it may have spaces, and not be a valid URI.
    class CreateWithRemoteFilesOrderedMembersActor < CreateWithRemoteFilesActor
      attr_reader :ordered_members

      # @param [HashWithIndifferentAccess] remote_files
      # @return [TrueClass]
      def attach_files(env, remote_files)
        return true unless remote_files
        @ordered_members = env.curation_concern.ordered_members.to_a
        remote_files.each do |file_info|
          next if file_info.blank? || file_info[:url].blank?
          # Escape any space characters, so that this is a legal URI
          uri = URI.parse(Addressable::URI.escape(file_info[:url]))
          unless validate_remote_url(uri)
            Rails.logger.error "User #{env.user.user_key} attempted to ingest file from url #{file_info[:url]}, which doesn't pass validation"
            return false
          end
          auth_header = file_info.fetch(:auth_header, {})
          create_file_from_url(env, uri, file_info[:file_name], auth_header)
        end
        add_ordered_members(env.user, env.curation_concern)
        true
      end

      # Generic utility for creating FileSet from a URL
      # Used in to import files using URLs from a file picker like browse_everything
      def create_file_from_url(env, uri, file_name, auth_header = {})
        ::FileSet.new(import_url: uri.to_s, label: file_name) do |fs|
          actor = file_set_actor_class.new(fs, env.user)
          actor.create_metadata(visibility: env.curation_concern.visibility)
          actor.attach_to_work(env.curation_concern)
          fs.save!
          ordered_members << fs
          if uri.scheme == 'file'
            # Turn any %20 into spaces.
            file_path = CGI.unescape(uri.path)
            IngestLocalFileJob.perform_later(fs, file_path, env.user)
          else
            ImportUrlJob.perform_later(fs, operation_for(user: actor.user), auth_header)
          end
        end
      end

      # Add all file_sets as ordered_members in a single action
      def add_ordered_members(user, work)
        actor = Hyrax::Actors::OrderedMembersActor.new(ordered_members, user)
        actor.attach_ordered_members_to_work(work)
      end

      class_attribute :file_set_actor_class
      self.file_set_actor_class = Hyrax::Actors::FileSetOrderedMembersActor
    end
  end
end
