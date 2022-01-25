# coding: utf-8
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
  #   - `file.set`: events related to the lifecycle of Hydra Works FileSets
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
  # Below is an example of subscribing using an anonymous block.  A
  # potential disadvantage of an anonymous block is that you cannot
  # easily unsubscribe to that block.
  #
  # @example subscribing to an event type/stream with a block handler
  #   publisher = Hyrax::Publisher.instance
  #
  #   publisher.subscribe('object.deposited') do |event|
  #     do_something(event[:object])
  #   end
  #
  # Below is an example of subscribing using an object.  A potential
  # advantage of subscribing with an object is that you can later
  # unsubscribe the object.
  #
  # @example subscribing to an event type/stream with an event listener.
  #
  #   class EventListener
  #     # @param event [#[]] The given event[:object] should be the deposited object.
  #     def on_object_deposited(event)
  #       do_something(event[:object])
  #     end
  #   end
  #   event_listener = EventListener.new
  #
  #   publisher = Hyrax::Publisher.instance
  #
  #   publisher.subscribe(event_listener)
  #
  #   # The above subscribed event_listener instance will receive an #on_object_deposited message
  #   # with an event that has two keys: `:object` and `:user`
  #   publisher.publish('object.deposited', object: deposited_object, user: depositing_user)
  #
  #   publisher.unsubscribe(event_listener)
  #
  # @see https://dry-rb.org/gems/dry-events/0.2/
  # @see Dry::Events::Publisher
  # @see https://github.com/samvera/hyrax/wiki/Hyrax's-Event-Bus-(Hyrax::Publisher)
  class Publisher
    include Singleton
    include Dry::Events::Publisher[:hyrax]

    # @!group Registered Events
    #
    # 🛑 👀 ❓
    # are you adding an event?
    # make sure Hyrax is publishing events in the correct places (this is be non-trivial!)
    # and add it to the list at https://github.com/samvera/hyrax/wiki/Hyrax's-Event-Bus-(Hyrax::Publisher)

    # @!macro [new] a_registered_event
    #   @!attribute [r] $1

    # @since 3.0.0
    # @macro a_registered_event
    register_event('batch.created')

    # @since 3.0.0
    # @macro a_registered_event
    #   @note this event SHOULD be published whevener the metadata is saved
    #     for a PCDM Collection. the payload for each published event MUST
    #     include an `:collection` (the updated Collection) AND a `:user` (the
    #     {::User} responsible for the update). the event SHOULD NOT be
    #     published for changes that only impact membership properties
    #     (`#member_of_ids`, `#member_of_collection_ids`, and `#member_ids`)
    register_event('collection.metadata.updated')

    # @since 3.0.0
    # @macro a_registered_event
    #   @note this event SHOULD be published whevener the membership is changed
    #     for a PCDM Collection. this includes changes to the Collection's
    #     `#member_ids` attribute, as well as inverse membership changes via
    #     another Collection/Object's `#member_of_ids` or
    #     `#member_of_collection_ids` attribute. the event payload MUST include
    #     either a `:collection` OR a `:collection_id` (the Collection OR its
    #     unique id), AND a `:user` (the ::User responsible for the update).
    register_event('collection.membership.updated')

    # @since 3.3.0
    # @macro a_registered_event
    register_event('file.downloaded')

    # @since 3.0.0
    # @macro a_registered_event
    register_event('file.set.audited')

    # @since 3.0.0
    # @macro a_registered_event
    register_event('file.set.attached')

    # @since 3.0.0
    # @macro a_registered_event
    register_event('file.set.url.imported')

    # @since 3.0.0
    # @macro a_registered_event
    register_event('file.set.restored')

    # @since 3.0.0
    # @macro a_registered_event
    register_event('object.deleted')

    # @since 3.0.0
    # @macro a_registered_event
    register_event('object.failed_deposit')

    # @since 3.0.0
    # @macro a_registered_event
    register_event('object.deposited')

    # @since 3.0.0
    # @macro a_registered_event
    register_event('object.acl.updated')

    # @since 3.4.0
    # @macro a_registered_event
    #   @note this event SHOULD be published whevener the membership is changed
    #     for a PCDM Object (including a Hydra Works FileSet). this includes
    #     changes to the Object's `#member_ids` attribute, as well as inverse
    #     membership changes via another Object's `#member_of_ids` attribute.
    #     the event payload MUST include either an `:object` OR an `:object_id`
    #     (the Object OR its unique id), AND a `:user` (the ::User responsible
    #     for the update).
    register_event('object.membership.updated')

    # @since 3.0.0
    # @macro a_registered_event
    #   @note this event SHOULD be published whevener the metadata is saved
    #     for a PCDM Object (including a Hydra Works FileSet). the payload for
    #     each published event MUST include an `:object` (the updated Object),
    #     AND a `:user` (the ::User responsible for the update). the event
    #     SHOULD NOT be published for changes that only impact membership
    #     properties (`#member_of_ids`, `#member_of_collection_ids`, and
    #     `#member_ids`)
    register_event('object.metadata.updated')

    # @since 3.2.0
    # @macro a_registered_event
    register_event('object.file.uploaded')
  end
end
