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
          @query_service.find_parents(resource: file_set).each do |parent|
            # do_it(parent, file_set, user)
            # byebug
            puts "remove_file_set_form_work.call for each parent"
            puts "file_set.id=#{file_set.id}"
            puts "parent.member_ids=#{parent.member_ids}"
            puts "parent.thumbnail_id=#{parent.thumbnail_id}"
            puts "parent.representative_id=#{parent.representative_id}"
            parent.member_ids -= [file_set.id]
            # parent&.unlink_file_set(file_set: file_set)
            unlink_file_set(parent: parent, file_set: file_set)
            puts "remove_file_set_form_work.call for each parent after unlink"
            puts "file_set.id=#{file_set.id}"
            puts "parent.member_ids=#{parent.member_ids}"
            puts "parent.thumbnail_id=#{parent.thumbnail_id}"
            puts "parent.representative_id=#{parent.representative_id}"
            # byebug
            saved = @persister.save(resource: parent)
            puts "remove_file_set_form_work.call for each parent after persister.save parent"
            puts "file_set.id=#{file_set.id}"
            puts "parent.member_ids=#{parent.member_ids}"
            puts "parent.thumbnail_id=#{parent.thumbnail_id}"
            puts "parent.representative_id=#{parent.representative_id}"
            Hyrax.publisher.publish('object.metadata.updated', object: saved, user: user)
          end

          Success(file_set)
        end

        def unlink_file_set(parent:, file_set:)
          puts "unlink_file_set -- begin"
          fid = file_set.id
          return false unless (parent.thumbnail_id == fid || parent.representative_id == fid ||
            (parent.respond_to?(:rendering_ids) && parent.rendering_ids.present? && parent.rendering_ids.include?(fid)) )
          # byebug
          puts "unlink_file_set -- something to unlink"
          puts "fid=#{fid}"
          puts "parent.thumbnail_id=#{parent.thumbnail_id}"
          if parent.thumbnail_id == fid
            puts "unlinking thumbnail"
            parent.thumbnail = nil if parent.respond_to? :thumbnail
            parent.thumbnail_id = nil
          end
          puts "fid=#{fid}"
          puts "parent.thumbnail_id=#{parent.thumbnail_id}"
          puts "parent.representative_id=#{parent.representative_id}"
          puts "unlinking representative_id"
          parent.representative_id = nil if parent.representative_id == fid
          puts "fid=#{fid}"
          puts "parent.thumbnail_id=#{parent.thumbnail_id}"
          puts "parent.representative_id=#{parent.representative_id}"
          if parent.respond_to?(:rendering_ids) && parent.rendering_ids.present?
            puts "unlinking rendering_ids"
            puts "fid=#{fid}"
            puts "parent.rendering_ids=#{parent.rendering_ids}"
            parent.rendering_ids = parent.rendering_ids - [fid]
            puts "fid=#{fid}"
            puts "parent.rendering_ids=#{parent.rendering_ids}"
          end
          # save
          true
        end

        def do_it(parent, file_set, user)
          parent.member_ids -= [file_set.id]
          parent&.unlink_file_set(file_set: file_set)
          # byebug
          saved = @persister.save(resource: parent)
          Hyrax.publisher.publish('object.metadata.updated', object: saved, user: user)
        end
      end
    end
  end
end
