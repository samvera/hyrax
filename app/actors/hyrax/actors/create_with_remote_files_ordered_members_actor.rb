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
      self.file_set_actor_class = Hyrax::Actors::FileSetOrderedMembersActor

      # @param [HashWithIndifferentAccess] remote_files
      # @return [TrueClass]
      def attach_files(env, remote_files)
        @ordered_members = env.curation_concern.ordered_members.to_a
        ingest_remote_files_service_class.new(user: env.user,
                                              curation_concern: env.curation_concern,
                                              remote_files: remote_files,
                                              ordered_members: @ordered_members,
                                              ordered: true,
                                              file_set_actor_class: file_set_actor_class).attach!
      end
    end
  end
end
