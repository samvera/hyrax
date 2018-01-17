# Gather information about the resources a depositor has contributed to the repository
module Hyrax
  module Statistics
    module Depositors
      class Depositor
        include Blacklight::SearchHelper

        # @api public
        # @param [String] depositor specify the depositor to gather the stats for
        # @return [Number] the count of works deposited by this user
        def self.works(depositor:)
          new(depositor).works
        end

        # @api public
        # @param [String] depositor specify the depositor to gather the stats for
        # @return [Number] the count of file sets deposited by this user
        def self.file_sets(depositor:)
          new(depositor).file_sets
        end

        # @api public
        # @param [String] depositor specify the depositor to gather the stats for
        # @return [Number] the count of collections deposited by this user
        def self.collections(depositor:)
          new(depositor).collections
        end

        # @param [String] depositor specify the depositor to gather the stats for
        def initialize(depositor)
          @depositor = depositor
        end

        def works
          count(works_query)
        end

        def file_sets
          count(file_sets_query)
        end

        def collections
          count(collections_query)
        end

        private

          delegate :blacklight_config, to: CatalogController

          def count(query)
            repository.search(query).response["numFound"]
          end

          def works_query
            Hyrax::WorksSearchBuilder.new([:by_depositor, :filter_models], self).with(depositor: @depositor).query
          end

          def file_sets_query
            Hyrax::FileSetsSearchBuilder.new([:by_depositor, :filter_models], self).with(depositor: @depositor).query
          end

          def collections_query
            Hyrax::CollectionSearchBuilder.new([:by_depositor, :filter_models], self).with(depositor: @depositor).query
          end
      end
    end
  end
end
