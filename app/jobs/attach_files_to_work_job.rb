# Converts UploadedFiles into FileSets and attaches them to works.
class AttachFilesToWorkJob < Hyrax::ApplicationJob
  queue_as Hyrax.config.ingest_queue_name

  # @param [ActiveFedora::Base] work - the work object
  # @param [Array<Hyrax::UploadedFile>] uploaded_files - an array of files to attach
  def perform(work, uploaded_files, **work_attributes)
    case work
    when ActiveFedora::Base
      perform_af(work, uploaded_files, work_attributes)
    when Valkyrie::Resource
      perform_valkyrie(work, uploaded_files, work_attributes)
    end
  end

  private

    def perform_af(work, uploaded_files, work_attributes)
      validate_files!(uploaded_files)
      depositor = proxy_or_depositor(work)
      user = User.find_by_user_key(depositor)

      work, work_permissions = create_permissions work, depositor
      metadata = visibility_attributes(work_attributes)
      uploaded_files.each do |uploaded_file|
        next if uploaded_file.file_set_uri.present?

        actor = Hyrax::Actors::FileSetActor.new(FileSet.create, user)
        uploaded_file.add_file_set!(actor.file_set)
        actor.file_set.permissions_attributes = work_permissions
        actor.create_metadata(metadata)
        actor.create_content(uploaded_file)
        actor.attach_to_work(work)
      end
    end

    def perform_valkyrie(work, uploaded_files, work_attributes)
      validate_files!(uploaded_files)
      depositor = proxy_or_depositor(work)
      user = User.find_by_user_key(depositor)
      work_permissions = permissions_map(work.permission_manager.acl.permissions)
      uploaded_files.each do |uploaded_file|
        next if uploaded_file.file_set_uri.present?
        attach_uploaded_file!(uploaded_file, user, work, work_permissions, work_attributes)
      end
    end

    def attach_uploaded_file!(uploaded_file, user, work, work_permissions, work_attributes)
      file_set = Hyrax.persister.save(resource: Hyrax::FileSet.new(user: user))
      actor = Hyrax::Actors::FileSetActor.new(file_set, user)
      uploaded_file.add_file_set!(actor.file_set)
      file_acl = Hyrax::AccessControlList.new(resource: actor.file_set)
      work_permissions.each { |perm| file_acl.grant(perm[:mode]).to(perm[:agent]).save }
      file_acl.save
      metadata = visibility_attributes(work_attributes)
      actor.create_metadata(metadata)
      actor.create_content(uploaded_file)
      actor.attach_to_work(work)
    end

    # Return array of hashes representing permissions without their :access_to objects
    # @param permissions [Permission]
    # @return [Array<Hash>]
    def permissions_map(permissions)
      permissions.collect { |p| { agent: agent_object(p.agent), mode: p.mode } }
    end

    # Converts string representation of Permission.agent to either User or Hyrax::Group
    # @param agent [String]
    # @return [User] or [Hyrax::Group]
    def agent_object(agent)
      return Hyrax::Group.new(agent.sub(Hyrax::Group.name_prefix, '')) if agent.starts_with?(Hyrax::Group.name_prefix)
      User.find_by_user_key(agent)
    end

    def create_permissions(work, depositor)
      work.edit_users += [depositor]
      work.edit_users = work.edit_users.dup
      work_permissions = work.permissions.map(&:to_hash)
      [work, work_permissions]
    end

    # The attributes used for visibility - sent as initial params to created FileSets.
    def visibility_attributes(attributes)
      attributes.slice(:visibility, :visibility_during_lease,
                       :visibility_after_lease, :lease_expiration_date,
                       :embargo_release_date, :visibility_during_embargo,
                       :visibility_after_embargo)
    end

    def validate_files!(uploaded_files)
      uploaded_files.each do |uploaded_file|
        next if uploaded_file.is_a? Hyrax::UploadedFile
        raise ArgumentError, "Hyrax::UploadedFile required, but #{uploaded_file.class} received: #{uploaded_file.inspect}"
      end
    end

    ##
    # A work with files attached by a proxy user will set the depositor as the intended user
    # that the proxy was depositing on behalf of. See tickets #2764, #2902.
    def proxy_or_depositor(work)
      work.on_behalf_of.blank? ? work.depositor : work.on_behalf_of
    end
end
