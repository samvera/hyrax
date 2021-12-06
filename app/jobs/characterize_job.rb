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
    filepath = Hyrax::WorkingDirectory.find_or_retrieve(file_id, file_set.id) unless filepath && File.exist?(filepath)
    characterize(file_set, file_id, filepath)
    CreateDerivativesJob.perform_later(file_set, file_id, filepath)
  end

  private

  def characterize(file_set, _file_id, filepath)
    characterization_service.run(file_set.characterization_proxy, filepath)
    Rails.logger.debug "Ran characterization on #{file_set.characterization_proxy.id} (#{file_set.characterization_proxy.mime_type})"
    file_set.characterization_proxy.alpha_channels = channels(filepath) if file_set.image? && Hyrax.config.iiif_image_server?
    file_set.characterization_proxy.save!
    file_set.update_index
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
