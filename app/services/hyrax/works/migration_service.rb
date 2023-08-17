# frozen_string_literal: true
module Hyrax
  module Works
    class MigrationService
      # @api public
      #
      # Migrate data stored in FCrepo from one predicate to another
      #   The main use case is where the predicate used for a specific property is changed.
      #   Data already stored in Fedora under the original predicate needs to be transfered
      #   and the original data cleaned up.
      def self.migrate_predicate(predicate_from, predicate_to, works_to_update = ActiveFedora::Base.all)
        migrated = 0
        Hyrax.logger.info "*** Migrating #{predicate_from} to #{predicate_to} in #{works_to_update.count} works"
        works_to_update.each do |work|
          next unless work.ldp_source.content.include?(predicate_from.to_s)
          migrate_data(predicate_from, predicate_to, work)
          migrated += 1
        end
        Hyrax.logger.info "--- Migration Complete (#{migrated} migrated)"
      end

      # @api private
      #
      # Migrate data
      def self.migrate_data(predicate_from, predicate_to, work)
        orm = Ldp::Orm.new(work.ldp_source)
        orm.value(predicate_from).each { |val| orm.graph.insert([orm.resource.subject_uri, predicate_to, val.to_s]) }
        orm.graph.delete([orm.resource.subject_uri, predicate_from, nil])
        orm.save
        Hyrax.logger.info " Data migrated from #{predicate_from} to #{predicate_to} - id: #{work.id}"
      end
    end
  end
end
