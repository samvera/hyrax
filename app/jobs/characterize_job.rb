# frozen_string_literal: true

##
# a +ActiveJob+ job to process file characterization.
#
# the characterization process is handled by a service object, which is
# configurable via {CharacterizeJob.characterization_service}.
#
# @example setting a custom characterization service
#   class MyCharacterizer
#     def run(file, path)
#       # do custom characterization
#     end
#   end
#
#   # in a Rails initializer
#   CharacterizeJob.characterization_service = MyCharacterizer.new
# end
class CharacterizeJob < Hyrax::ApplicationJob
  queue_as Hyrax.config.ingest_queue_name

  class_attribute :characterization_service
  self.characterization_service = Hydra::Works::CharacterizationService

  # Characterizes the file at 'filepath' if available, otherwise, pulls a copy from the repository
  # and runs characterization on that file.
  # @param [FileSet] file_set
  # @param [String] file_id identifier for a Hydra::PCDM::File
  # @param [String, NilClass] filepath the cached file within the Hyrax.config.working_path
  def perform(file_set, file_id, filepath = nil)
    raise "#{file_set.class.characterization_proxy} was not found for FileSet #{file_set.id}" unless file_set.characterization_proxy?
    # Ensure a fresh copy of the repo file's latest version is being worked on, if no filepath is directly provided
    filepath = Hyrax::WorkingDirectory.copy_repository_resource_to_working_directory(Hydra::PCDM::File.find(file_id), file_set.id) unless filepath && File.exist?(filepath)
    characterize(file_set, file_id, filepath)

    Hyrax.publisher.publish('file.characterized',
                            file_set: file_set,
                            file_id: file_id,
                            path_hint: filepath)
  end

  private

  def characterize(file_set, _file_id, filepath) # rubocop:disable Metrics/AbcSize
    # store this so we can tell if the original_file is actually changing
    previous_checksum = file_set.characterization_proxy.original_checksum.first

    clear_metadata(file_set)

    # If the current FileSet title is the same as the label, it must be a filename as opposed to a user-entered...
    # value. So later we'll ensure it's set to the new file's filename.
    reset_title = file_set.title.first == file_set.label

    characterization_service.run(file_set.characterization_proxy, filepath, **Hyrax.config.characterization_options)
    Hyrax.logger.debug "Ran characterization on #{file_set.characterization_proxy.id} (#{file_set.characterization_proxy.mime_type})"
    file_set.characterization_proxy.alpha_channels = channels(filepath) if file_set.image? && Hyrax.config.iiif_image_server?
    file_set.characterization_proxy.save!

    # Ensure that if the actual file content has changed, the mod timestamp on the FileSet object changes.
    # Otherwise this does not happen when rolling back to a previous version. Perhaps this should be set as part of...
    # `FileActor.revert_to` (or its replacement Transaction?!), where the FileSet is saved. Not sure if the...
    # before/after checksum is readily available there though. I like this checksum verification because it allows...
    # all changes to the current FileSet version to be detected, which in our case triggers re-creation of a...
    # "cold storage" archive of the parent Work. It's worth noting that adding a *new* version always touches this...
    # mod time. This is done in the versioning code.
    file_set.date_modified = Hyrax::TimeService.time_in_utc if file_set.characterization_proxy.original_checksum.first != previous_checksum

    file_set.characterization_proxy.original_name.force_encoding("UTF-8")
    # set title to label (i.e. file name, `original_name`) if that's how it was before this characterization
    file_set.title = [file_set.characterization_proxy.original_name] if reset_title
    # always set the label to the original_name
    file_set.label = file_set.characterization_proxy.original_name

    file_set.save!
  end

  def clear_metadata(file_set)
    # The characterization of additional file versions adds new height/width/size/checksum values to un-orderable...
    # `ActiveTriples::Relation` fields on `original_file`. Values from those are then randomly pulled into Solr...
    # fields which may have scalar or vector cardinality. So for height/width you get two scalar values pulled from...
    # "randomized parallel arrays". Upshot is to reset all of these before (re)characterization to stop the mayhem.
    file_set.characterization_proxy.height = []
    file_set.characterization_proxy.width  = []
    file_set.characterization_proxy.original_checksum = []
    file_set.characterization_proxy.file_size = []
    file_set.characterization_proxy.format_label = []
  end

  def channels(filepath)
    ch = MiniMagick::Tool::Identify.new do |cmd|
      cmd.format '%[channels]'
      cmd << filepath
    end
    [ch]
  end

  ##
  # @api public
  # @return [#run]
  def characterization_service
    self.class.characterization_service
  end
end
