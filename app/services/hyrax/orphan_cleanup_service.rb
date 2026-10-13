# frozen_string_literal: true

module Hyrax
  ##
  # Finds what interrupted work deletions leave behind: file sets that no
  # work lists as a member, and index documents for works and file sets that
  # are no longer in the repository. Only reports them unless +delete+ is true.
  #
  # A file set is saved before its work's member_ids are, so one changed
  # within +min_age+ may belong to an upload still in progress and is skipped.
  #
  # @example
  #   Hyrax::OrphanCleanupService.new(delete: true).call
  #   # => { file_set_ids: ['abc'], failed_file_set_ids: [], index_ids: ['def'] }
  class OrphanCleanupService
    BATCH_SIZE = 500

    def initialize(delete: false, user: nil, min_age: 1.day, logger: Hyrax.logger)
      @delete = delete
      @user = user
      @min_age = min_age
      @logger = logger
    end

    # @return [Hash{Symbol => Array<String>}] ids of the orphaned file sets
    #   found (or removed), those that could not be destroyed, and the stray
    #   index documents
    def call
      removed, failed = orphan_file_sets.partition { |file_set| remove_file_set(file_set) }
      index_ids = stray_index_ids
      remove_index_documents(index_ids)
      { file_set_ids: ids_of(removed), failed_file_set_ids: ids_of(failed), index_ids: index_ids }
    end

    private

    # Wings answers find_parents from Solr, so a work missing from the index
    # would make its file sets look orphaned; deleting them could not be undone.
    def orphan_file_sets
      return skip_file_sets_on_wings if wings?

      cutoff = @min_age.ago
      member_ids = work_member_ids
      valkyrie_classes(Hyrax::ModelRegistry.file_set_classes).flat_map do |model|
        Hyrax.query_service.find_all_of_model(model: model)
             .select { |file_set| file_set.updated_at < cutoff && member_ids.exclude?(file_set.id.to_s) }
             .select { |file_set| Hyrax.query_service.find_parents(resource: file_set).none? }
             .to_a
      end
    end

    def work_member_ids
      valkyrie_classes(Hyrax::ModelRegistry.work_classes).each_with_object(Set.new) do |model, ids|
        Hyrax.query_service.find_all_of_model(model: model).each { |work| ids.merge(work.member_ids.map(&:to_s)) }
      end
    end

    def valkyrie_classes(classes)
      classes.select { |model| model <= Valkyrie::Resource }
    end

    # Goddess adapters (Freyja, Frigg) query Wings as one of their services.
    def wings?
      return false unless defined?(Wings::Valkyrie::QueryService)
      [Hyrax.query_service, *Hyrax.query_service.try(:services)].any? { |service| service.is_a?(Wings::Valkyrie::QueryService) }
    end

    def skip_file_sets_on_wings
      @logger.warn('Skipping the orphaned file set scan: Wings finds parents through Solr, which is not reliable enough to delete by')
      []
    end

    def stray_index_ids
      missing = []
      batch = []
      Hyrax::SolrService.query_in_batches(stray_candidates_query, fl: 'id', sort: 'id asc', rows: BATCH_SIZE) do |hit|
        batch << hit.id
        next if batch.size < BATCH_SIZE
        missing.concat(missing_from_repository(batch))
        batch = []
      end
      missing.concat(missing_from_repository(batch))
    end

    def missing_from_repository(ids)
      return [] if ids.empty?
      ids - Hyrax.query_service.find_many_by_ids(ids: ids).map { |resource| resource.id.to_s }
    end

    def stray_candidates_query
      models = Hyrax::ModelRegistry.work_rdf_representations + Hyrax::ModelRegistry.file_set_rdf_representations
      "{!terms f=has_model_ssim}#{models.uniq.join(',')}"
    end

    def remove_file_set(file_set)
      id = file_set.id.to_s
      @logger.info("#{@delete ? 'Destroying' : 'Found'} orphaned file set #{id}")
      return true unless @delete

      user = @user || ::User.system_user
      result = Hyrax::Transactions::Container['file_set.destroy']
               .with_step_args('file_set.remove_from_work' => { user: user }, 'file_set.delete' => { user: user })
               .call(file_set)
      @logger.error("Could not destroy orphaned file set #{id}: #{result.failure.inspect}") if result.failure?
      result.success?
    end

    def ids_of(resources)
      resources.map { |resource| resource.id.to_s }
    end

    def remove_index_documents(ids)
      ids.each { |id| @logger.info("#{@delete ? 'Removing' : 'Found'} stray index document #{id}") }
      return unless @delete
      ids.each_slice(BATCH_SIZE) { |batch| Hyrax::SolrService.delete(batch) }
    end
  end
end
