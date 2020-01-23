class CharacterizeJob < Hyrax::ApplicationJob
  queue_as Hyrax.config.ingest_queue_name
  attr_reader :use_valkyrie

  # Characterizes the file at 'filepath' if available, otherwise, pulls a copy from the repository
  # and runs characterization on that file.
  # @param [FileSet] file_set
  # @param [String] file_id identifier for a Hydra::PCDM::File
  # @param [String, NilClass] filepath the cached file within the Hyrax.config.working_path
  def perform(file_set, file_id, filepath = nil, use_valkyrie: Hyrax.config.use_valkyrie?)
    raise "#{file_set.class.characterization_proxy} was not found for FileSet #{file_set.id}" unless file_set.characterization_proxy?
    @use_valkyrie = use_valkyrie
    filepath = Hyrax::WorkingDirectory.find_or_retrieve(file_id, file_set.id) unless filepath && File.exist?(filepath)
    characterize(file_set, file_id, filepath)
    CreateDerivativesJob.perform_later(file_set, file_id, filepath)
  end

  private

    def characterize(file_set, _file_id, filepath)
      Hydra::Works::CharacterizationService.run(file_set.characterization_proxy, filepath)
      Rails.logger.debug "Ran characterization on #{file_set.characterization_proxy.id} (#{file_set.characterization_proxy.mime_type})"
      file_set.characterization_proxy.alpha_channels = channels(filepath) if file_set.image? && Hyrax.config.iiif_image_server?
      if use_valkyrie
        Hyrax.persister.save(resource: file_set.characterization_proxy)
        Hyrax.persister.save(resource: file_set)
        # Hyrax.metadata_adapter.query_service.find_parents(resource: file_set).select(&:work?).each do |work|
        #   Hyrax.metadata_adapter.query_service.find_parents(resource: work).select(&:collection?).each do |collection|
        #     Hyrax.persister.save(resource: collection)
        #   end
        # end
      else
        file_set.characterization_proxy.save!
        file_set.update_index
        file_set.parent&.in_collections&.each(&:update_index)
      end
    end

    def channels(filepath)
      ch = MiniMagick::Tool::Identify.new do |cmd|
        cmd.format '%[channels]'
        cmd << filepath
      end
      [ch]
    end
end
