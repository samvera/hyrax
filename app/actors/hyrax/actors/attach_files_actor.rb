module Hyrax
  module Actors
    class AttachFilesActor < AbstractActor
      # @param [Hyrax::Actors::Environment] env
      # @return [Boolean] true if create was successful
      def create(env)
        files = [env.attributes.delete(:files)].flatten.compact
        file_sets = attach_files(env, files, visibility_attributes(env.attributes))
        file_sets.all? { |fs| fs.is_a? ::FileSet } &&
          next_actor.create(env) && send_create_notifications(env, file_sets)
      end

      # @param [Hyrax::Actors::Environment] env
      # @return [Boolean] true if update was successful
      def update(env)
        files = [env.attributes.delete(:files)].flatten.compact
        next_actor.update(env) &&
          attach_files(env, files, visibility_attributes(env.attributes))
      end

      private

        # Run the after_create_fileset callback for each created FileSet
        def send_create_notifications(env, file_sets)
          file_sets.each do |file_set|
            Hyrax.config.callback.run(:after_create_fileset, file_set, env.user)
          end
        end

        # @return [Array<FileSet>] returns the list of FileSet objects that were created
        def attach_files(env, files, visibility_attr)
          files.map do |file|
            attach_file(env, file, visibility_attr)
          end
        end

        # @return [FileSet] the FileSet object that was created
        def attach_file(env, file, visibility_attr)
          ::FileSet.new do |file_set|
            file_set_actor = Hyrax::Actors::FileSetActor.new(file_set, env.user)
            file_set_actor.create_metadata(visibility_attr)
            file_set_actor.create_content(file)
            file_set_actor.attach_file_to_work(env.curation_concern, visibility_attr)
          end
        end

        # The attributes used for visibility - used to send as initial params to
        # created FileSets.
        def visibility_attributes(attributes)
          attributes.slice(:visibility, :visibility_during_lease,
                           :visibility_after_lease, :lease_expiration_date,
                           :embargo_release_date, :visibility_during_embargo,
                           :visibility_after_embargo)
        end
    end
  end
end
