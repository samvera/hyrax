# frozen_string_literal: true

module Hyrax
  ##
  # @api public
  #
  # Inline-create endpoint for the `linked_record` compound picker's
  # lookup-or-create flow. Source-agnostic: `params[:source]` selects a source
  # registered with {Hyrax::CompoundLinkedRecordResolver}, which owns how to
  # create the record and how to derive its label.
  #
  # Returns `{ id:, label: }` (201) on success, the record's errors (422) when
  # invalid, or 404 when the source is unknown or not creatable. The source's
  # `create` proc owns the attribute contract (declared via the profile's
  # `create_fields`), so the submitted `record` hash is passed through as-is.
  class CompoundLinkedRecordsController < ApplicationController
    def create
      source = params[:source].to_s
      return head(:not_found) unless Hyrax::CompoundLinkedRecordResolver.creatable?(source)

      record = Hyrax::CompoundLinkedRecordResolver.create(source, create_attributes)

      if record && record_valid?(record)
        render json: { id: record.id, label: Hyrax::CompoundLinkedRecordResolver.label_for(source, record.id) },
               status: :created
      else
        render json: { errors: record_errors(record) }, status: :unprocessable_entity
      end
    end

    private

    # Pass the submitted record attributes through to the source's create proc,
    # which decides what it accepts. The source owns the field contract (declared
    # via the profile's create_fields), so permit an open hash. A `group`
    # create-field arrives as an Array of Hashes (one per row); deep-symbolize so
    # the create proc sees symbol keys at every level, including nested rows.
    def create_attributes
      raw = params[:record]
      return {} unless raw.respond_to?(:to_unsafe_h) || raw.is_a?(ActionController::Parameters)

      raw.to_unsafe_h.deep_symbolize_keys
    end

    def record_valid?(record)
      record.respond_to?(:persisted?) ? record.persisted? : true
    end

    # Messages for an invalid record. Accepts either an ActiveModel errors object
    # (`full_messages`) or a plain array, since a source's `create` proc may
    # return any record-like object.
    def record_errors(record)
      return ['could not be created'] unless record.respond_to?(:errors)

      messages = record.errors.respond_to?(:full_messages) ? record.errors.full_messages : Array(record.errors)
      messages.presence || ['could not be created']
    end
  end
end
