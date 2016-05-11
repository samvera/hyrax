module CurationConcerns
  # Module for containing Actors
  # @since 0.14.0
  # An Actor coordinates the response to a user command
  # (often via user http request to a controller).  It
  # performs one or more steps in the business process of a
  # create, update, or destroy command issued by a user.
  # You may a have a stack of multiple actors that each
  # perform one action.  Actors should have a specific task
  # and be chained together to execute more complex business
  # purposes.
  # @example A series of actors responsible for creating an object:
  #   Metadata Writing Actor, Rights Assignment Actor,
  #   Indexing Actor
  # @see CurationConcerns::AbstractActor for primitive interface definition
  module Actors
  end
end
