# frozen_string_literal: true
require 'dry/monads'

module Hyrax
  module Transactions
    module Steps
      ##
      # removes the file set from all its parents, returning a
      # `Dry::Monads::Result` (`Success`|`Failure`).
      #
      # there should normally be only one parent for a FileSet, but in the case
      # that there are multiple, this step will remove the file set from all
      # parents.
      #
      # if no user is provided to attribute the removal to, the step fails
      # immediately.
      #
      # @see https://dry-rb.org/gems/dry-monads/1.0/result/
      class RemoveFileSetFromWork
        include Dry::Monads[:result]

        ##
        # @param [Valkyrie::QueryService] query_service
        def initialize(query_service: Hyrax.query_service, persister: Hyrax.persister)
          @persister     = persister
          @query_service = query_service
        end

        ##
        # @param [Hyrax::FileSet] file_set
        #
        # @return [Dry::Monads::Result]
        def call(file_set, user: nil)
          return Failure('No user provided.') if user.nil?
          find_parents(resource: file_set).each do |parent|
            parent.member_ids -= [file_set.id]
            unlink_file_set(parent: parent, file_set: file_set)
            saved = @persister.save(resource: parent)
            Hyrax.publisher.publish('object.metadata.updated', object: saved, user: user)
          end
          Success(file_set)
        end

        private

        def find_parents(resource:)
          @query_service.find_parents(resource: resource)
        end

        def unlink_file_set(parent:, file_set:)
          fid = file_set.id
          unlink_thumbnail_id(fid: fid, parent: parent)
          unlink_representative_id(fid: fid, parent: parent)
          unlink_rendering_ids(fid: fid, parent: parent)
        end

        def unlink_rendering_ids(fid:, parent:)
          parent.rendering_ids -= [fid] if parent.respond_to?(:rendering_ids) && parent.rendering_ids.present?
        end

        def unlink_representative_id(fid:, parent:)
          parent.representative_id = nil if parent.representative_id == fid
        end

        def unlink_thumbnail_id(fid:, parent:)
          return unless parent.thumbnail_id == fid
          parent.thumbnail = nil if parent.respond_to? :thumbnail
          parent.thumbnail_id = nil
        end
      end
    end
  end
end
