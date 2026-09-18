# frozen_string_literal: true
module Hyrax
  # Deletes zero-count Hyrax::Statistic rows in batches, keeping the most recent zero row per object (see Hyrax::Statistic#advance_zero_marker).
  class StatsPruner
    def self.call(klass:, id_column:, dry_run: false, batch_size: 50_000)
      new(klass: klass, id_column: id_column, dry_run: dry_run, batch_size: batch_size).call
    end

    def initialize(klass:, id_column:, dry_run:, batch_size:)
      @klass = klass
      @id_column = id_column
      @count_column = klass.cache_column
      @table = klass.quoted_table_name
      @dry_run = dry_run
      @batch_size = batch_size
    end

    def call
      before = klass.count
      connection.execute("CREATE TEMPORARY TABLE keepers AS #{keepers_sql}")
      connection.execute("CREATE INDEX ON keepers (#{id_column})")

      dry_run ? report_dry_run(before) : delete_in_batches(before)
    ensure
      connection.execute("DROP TABLE IF EXISTS keepers")
    end

    private

    attr_reader :klass, :id_column, :count_column, :table, :dry_run, :batch_size

    def connection
      klass.connection
    end

    def keepers_sql
      <<~SQL
        SELECT #{id_column}, MAX(date) AS keep_date
        FROM #{table}
        WHERE #{count_column} = 0
        GROUP BY #{id_column}
      SQL
    end

    def stale_rows_sql(limit: nil)
      <<~SQL
        SELECT stale.id FROM #{table} stale
        JOIN keepers ON stale.#{id_column} = keepers.#{id_column}
        WHERE stale.#{count_column} = 0 AND stale.date < keepers.keep_date
        #{"LIMIT #{limit}" if limit}
      SQL
    end

    def report_dry_run(before)
      count = connection.execute("SELECT count(*) FROM (#{stale_rows_sql}) redundant").first['count']
      Hyrax.logger.info("hyrax:stats:prune_zero_stats: #{klass} would delete #{count} of #{before} rows (dry run)")
    end

    def delete_in_batches(before)
      loop do
        deleted = connection.execute("DELETE FROM #{table} WHERE id IN (#{stale_rows_sql(limit: batch_size)})").cmd_tuples
        Hyrax.logger.info("hyrax:stats:prune_zero_stats: #{klass} deleted #{deleted} rows")
        break if deleted < batch_size
      end
      Hyrax.logger.info("hyrax:stats:prune_zero_stats: #{klass} #{before} -> #{klass.count} rows")
    end
  end
end
