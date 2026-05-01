# frozen_string_literal: true

module Hyrax
  # Validates the `redirects` attribute on a work or collection. Runs only
  # when the redirects feature is fully enabled (config + Flipflop).
  #
  # Path normalization happens upstream of this validator (in
  # `Hyrax::Forms::ResourceForm#redirects=`), so the entries this
  # validator sees already match the canonical form stored in
  # `hyrax_redirect_paths` and queried by the resolver.
  #
  # See documentation/redirects.md for the validation rules.
  class RedirectValidator < ActiveModel::EachValidator
    PATH_FORMAT = %r{\A/[^?\s#]+\z}.freeze

    def validate_each(record, attribute, entries)
      return unless Hyrax.config.redirects_enabled? && Flipflop.redirects?
      return if entries.blank?

      validate_each_entry(record, attribute, entries)
      validate_intra_record_uniqueness(record, attribute, entries)
      validate_global_uniqueness(record, attribute, entries)
      validate_at_most_one_canonical(record, attribute, entries)
    end

    private

    def validate_each_entry(record, attribute, entries)
      entries.each do |entry|
        path = entry.try(:path)
        if path.blank?
          record.errors.add(attribute, message_for(:blank))
        elsif !PATH_FORMAT.match?(path)
          record.errors.add(attribute, message_for(:invalid_format, path: path))
        elsif Hyrax.config.reserved_redirect_prefixes.any? { |prefix| path == prefix || path.start_with?("#{prefix}/") }
          record.errors.add(attribute, message_for(:reserved_prefix, path: path))
        end
      end
    end

    def validate_intra_record_uniqueness(record, attribute, entries)
      paths = entries.map { |entry| entry.try(:path) }.compact
      duplicates = paths.tally.select { |_, count| count > 1 }.keys
      duplicates.each do |path|
        record.errors.add(attribute, message_for(:intra_record_duplicate, path: path))
      end
    end

    def validate_global_uniqueness(record, attribute, entries)
      except_id = record.try(:id)
      entries.each do |entry|
        path = entry.try(:path)
        next if path.blank?
        next unless Hyrax::RedirectsLookup.taken?(path, except_id: except_id)
        record.errors.add(attribute, message_for(:already_taken, path: path))
      end
    end

    def validate_at_most_one_canonical(record, attribute, entries)
      canonical_count = entries.count { |entry| entry.try(:canonical) }
      return if canonical_count <= 1
      record.errors.add(attribute, message_for(:multiple_canonical))
    end

    def message_for(key, **interpolations)
      I18n.t(key, scope: 'errors.messages.redirect', **interpolations)
    end
  end
end
