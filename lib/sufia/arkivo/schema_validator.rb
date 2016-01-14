require 'json-schema'

module Sufia
  module Arkivo
    ITEM_SCHEMA = {
      type: 'object',
      properties: {
        token: { type: 'string', required: true },
        metadata: {
          type: 'object',
          required: true,
          properties: {
            title: { type: 'string', required: true },
            rights: { type: 'string', required: true },
            resourceType: { type: 'string' },
            description: { type: 'string' },
            publisher: { type: 'string' },
            dateCreated: { type: 'string' },
            basedNear: { type: 'string' },
            identifier: { type: 'string' },
            url: { type: 'string' },
            language: { type: 'string' }
          }
        },
        file: {
          type: 'object',
          required: true,
          properties: {
            base64: { type: 'string', required: true },
            md5: { type: 'string', required: true },
            filename: { type: 'string', required: true },
            contentType: { type: 'string', required: true }
          }
        }
      }
    }.freeze

    class InvalidItem < RuntimeError
    end

    class SchemaValidator
      attr_reader :item

      def initialize(item)
        @item = item
      end

      def call
        JSON::Validator.validate!(Sufia::Arkivo::ITEM_SCHEMA, item, version: :draft3)
      rescue JSON::Schema::ValidationError => exception
        raise Sufia::Arkivo::InvalidItem, exception.message
      end
    end
  end
end
