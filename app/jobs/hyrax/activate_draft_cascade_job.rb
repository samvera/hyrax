# frozen_string_literal: true
module Hyrax
  ##
  # Walks the full membership tree of a work that has just been published out of
  # draft and applies the chosen active visibility to every descendant (child
  # works and file sets, at any depth), activating suppressed works so they leave
  # the draft state.
  #
  # A visited set guards against membership cycles.
  #
  # @see Hyrax::Workflow::ActivateDraftCascade
  class ActivateDraftCascadeJob < Hyrax::ApplicationJob
    ##
    # @param root_id [String] id of the work whose members should be promoted
    # @param visibility [String] the chosen active visibility to apply
    def perform(root_id, visibility)
      root = Hyrax.query_service.find_by(id: root_id)
      cascade(root, visibility, Set.new)
    rescue Valkyrie::Persistence::ObjectNotFoundError, Hyrax::ObjectNotFoundError
      Hyrax.logger.warn("ActivateDraftCascadeJob: could not find root #{root_id}; skipping cascade")
    end

    private

    ##
    # Recurse child works (which can have their own members) and promote every
    # member. File sets are leaves, so they are promoted but not recursed into.
    def cascade(resource, visibility, visited)
      return if visited.include?(resource.id.to_s)
      visited << resource.id.to_s

      child_works = Hyrax.custom_queries.find_child_works(resource: resource)
      child_file_sets = Hyrax.custom_queries.find_child_file_sets(resource: resource)

      child_file_sets.each { |file_set| promote(file_set, visibility) }

      child_works.each do |child_work|
        promote(child_work, visibility)
        cascade(child_work, visibility, visited)
      end
    end

    ##
    # Apply the chosen visibility and (for works) return to the active state so
    # the object stops being suppressed. Persist and reindex so search hiding and
    # visibility update.
    def promote(resource, visibility)
      resource.visibility = visibility
      resource.state = Hyrax::ResourceStatus::ACTIVE if resource.respond_to?(:state=)
      resource.permission_manager.acl.save if resource.respond_to?(:permission_manager)

      saved = Hyrax.persister.save(resource: resource)
      Hyrax.index_adapter.save(resource: saved)
    end
  end
end
