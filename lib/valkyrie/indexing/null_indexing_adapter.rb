# frozen_string_literal: true
module Valkyrie
  module Indexing
    # A Valkyrie indexer that does nothing for all index requests. This is
    # useful for applications using alternate/legacy (e.g. ActiveFedora)
    # indexing strategies that don't want the overhead of running separate
    # index requests.
    #
    # rubocop:disable Lint/UnusedMethodArgument RuboCop wants us to accept all
    #   arguments, but we actually want to raise ArgumentError when the caller
    #   isn't using the correct signature.
    class NullIndexingAdapter
      def save(resource:)
        :noop
      end

      def save_all(resources:)
        :noop
      end

      def delete(resource:)
        :noop
      end

      def wipe!
        :noop
      end
    end
    # rubocop:enable Lint/UnusedMethodArgument
  end
end
