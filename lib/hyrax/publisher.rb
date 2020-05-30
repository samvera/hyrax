# frozen_string_literal: true

module Hyrax
  ##
  # This is an application-wide publisher for Hyrax's Pub/Sub interface.
  #
  # Hyrax publishes events on a variety of streams. The streams are namespaced
  # using `dry-rb`'s dot notation idiom to help with organization. Namespaces
  # reflect the kinds of resources the event applied to.
  #
  #   - `batch`: events related to the performance of `BatchCreateJob`
  #   - `file_set`: events related to the lifecycle of Hydra Works FileSets
  #   - `object`: events related to the lifecycle of all PCDM Objects
  #
  # Applications *SHOULD* publish events whenever the relevant actions are
  # performed. While Hyrax provides certain out-of-the-box listeners to power
  # (e.g.) notifications, event streams are useful for much more: implementing
  # local logging or instrumentation, adding application-specific callback-like
  # handlers, etc... Ensuring events are consistently published is key to their
  # usefulness.
  #
  # @note this API replaces an older `Hyrax::Callbacks` interface, with added
  #   thread safety and capacity for many listeners on a single publication
  #   stream.
  #
  # @note we call this "Publisher" to differentiate from the `Hyrax::Event`
  #   model. This class is a `Dry::Events` publisher.
  #
  # @todo audit Hyrax code (and dependencies!) for places where events should be
  #   published, but are not.
  #
  # @example publishing an event
  #   publisher = Hyrax::Publisher.instance
  #
  #   publisher.publish('object.deposited', object: deposited_object, user: depositing_user)
  #
  # @example use Hyrax.publisher
  #   Hyrax.publisher.publish('object.deposited', object: deposited_object, user: depositing_user)
  #
  # @example subscribing to an event type/stream with a block handler
  #   publisher = Hyrax::Publisher.instance
  #
  #   publisher.subscribe('object.deposited') do |event |
  #     do_something(event[:object])
  #   end
  #
  # @see https://dry-rb.org/gems/dry-events/0.2/
  # @see Dry::Events::Publisher
  class Publisher
    include Singleton
    include Dry::Events::Publisher[:hyrax]

    register_event('batch.created')
    register_event('file.set.audited')
    register_event('file.set.attached')
    register_event('file.set.url.imported')
    register_event('file.set.restored')
    register_event('object.deleted')
    register_event('object.failed_deposit')
    register_event('object.deposited')
    register_event('object.acl.updated')
    register_event('object.metadata.updated')
  end
end
