# frozen_string_literal: true
module Hyrax
  module TestDataSeeders
    # This class was created for use in rake tasks and db/seeds.rb.  It generates
    # collection types that can be used in release testing.  This data can also be
    # helpful for local development testing.
    #
    # Adding collection types is non-destructive.  If a collection type with the
    # title already exists, it will not be replaced.
    class CollectionTypeSeeder
      class << self
        attr_accessor :logger

        def generate_seeds(logger: Logger.new(STDOUT), allow_seeding_in_production: false) # rubocop:disable Metrics/MethodLength
          raise("TestDataSeeders are not for use in production!") if Rails.env.production? && !allow_seeding_in_production
          @logger = logger

          logger.info("Adding collection types...")

          create_collection_type(title: "Nestable only", badge_color: "#282D3C", nestable: true,
                                 description: "Collections of this type can be nested.")
          create_collection_type(title: "Brandable only", badge_color: "#ff6600", brandable: true,
                                 description: "Collections of this type can have branding images.")
          create_collection_type(title: "Discoverable only", badge_color: "#00A170", discoverable: true,
                                 description: "Collections of this type can have visibility settings modified.")
          create_collection_type(title: "Sharable only", badge_color: "#ff0066", sharable: true, share_applies_to_new_works: false,
                                 description: "Collections of this type are sharable.  Works " \
                                              "do NOT inherit sharable settings when they are created.")
          create_collection_type(title: "Sharable only (and works)", badge_color: "#0072B5", sharable: true, share_applies_to_new_works: true,
                                 description: "Collections of this type are sharable.  Works " \
                                              "inherit sharable settings when they are created.")
          create_collection_type(title: "Single Membership 1", badge_color: "#b34700", allow_multiple_membership: false,
                                 description: "This Single Membership 1 collection type restricts collection membership. " \
                                              "Collections of this type do not allow works to live in multiple collections of this type.")
          create_collection_type(title: "Single Membership 2", badge_color: "#926AA6", allow_multiple_membership: false,
                                 description: "This Single Membership 2 collection type restricts collection membership. " \
                                              "Collections of this type do not allow works to live in multiple collections of this type.")
        end

        private

        def collection_type_titles
          @collection_type_titles ||= Hyrax::CollectionType.all.map(&:title)
        end

        def create_collection_type(options = {})
          title = options[:title]
          return logger.info("   #{title} -- ALREADY EXISTS") if collection_type_titles.include? title

          defaults_for_options(options)
          Hyrax::CollectionType.new(options).save
          logger.info("   #{title} -- CREATED")
        end

        def defaults_for_options(options = {})
          options[:nestable] ||= false
          options[:brandable] ||= false
          options[:discoverable] ||= false
          options[:sharable] ||= false
          options[:share_applies_to_new_works] ||= false
          options[:allow_multiple_membership] ||= true

          # These should always false unless the collection type is Admin Set.
          # Admin Set collection type is created by required_data_seeders
          options[:require_membership] = false
          options[:assigns_workflow] = false
          options[:assigns_visibility] = false
        end
      end
    end
  end
end
