# frozen_string_literal: true
module Hyrax
  ##
  # These custom queries are used throughout the Hyrax codebase. They are
  # intended for use with Valkyrie's custom query interface (i.e. you
  # shouldn't call classes in this namespace directly except to configure that
  # interface).
  #
  # In this namespace, we provide default/reference implementations, with the
  # restriction that they cannot use any adapter-specific knowledge. I.e. these
  # queries use the Valkyrie core queries and client side data manipulation
  # only. This restriction limits performance expectations for these
  # implementations, but guarantees a basic level of compatibility for all
  # conforming Valkyrie adapters.
  #
  # In order for a Valkyrie adapter to be "supported" by Hyrax, these queries
  # should be individually evaluated for performance when using the adapter.
  # Where appropriate, optimized implementations should be provided taking
  # advantage of backend-specific query features.
  #
  # @see https://github.com/samvera/valkyrie/wiki/Queries#custom-queries
  # @see https://github.com/samvera/hyrax/wiki/Hyrax-Valkyrie-Usage-Guide#custom-queriesy
  module CustomQueries
  end
end
