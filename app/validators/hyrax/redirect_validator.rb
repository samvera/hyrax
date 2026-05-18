# frozen_string_literal: true

module Hyrax
  # Validates the `redirects` attribute on a work or collection. Runs only
  # when the redirects feature is fully enabled (config + Flipflop).
  #
  # See documentation/redirects.md for the validation rules.
  class RedirectValidator < ActiveModel::EachValidator
    PATH_FORMAT = %r{\A/[^?\s#]+\z}.freeze

    # Override `validate` so we can short-circuit before ActiveModel calls
    # `record.read_attribute_for_validation`, which would crash on records
    # that don't have the `redirects` attribute.
    #
    # Two guards, each catching a distinct case:
    # 1. config + Flipflop — the runtime feature gate. Skips validation when
    #    the feature isn't actively in use.
    # 2. record_supports_redirects? — the structural gate. Catches the case
    #    where both feature gates are on but the property wasn't added
    def validate(record)
      return unless Hyrax.config.redirects_active?
      return unless record_supports_redirects?(record)
      super
    end

    def validate_each(record, attribute, entries)
      return if entries.blank?

      validate_each_entry(record, attribute, entries)
      validate_intra_record_uniqueness(record, attribute, entries)
      validate_global_uniqueness(record, attribute, entries)
      validate_at_most_one_canonical(record, attribute, entries)
    end

    private

    # Entries are persisted hashes, but the form-render path may pass
    # Hyrax::Redirect presenter instances. Both shapes are acceptable.
    def path_for(entry)
      return entry.path if entry.respond_to?(:path)
      return entry['path'] || entry[:path] if entry.respond_to?(:[])
      nil
    end

    def canonical_for(entry)
      return entry.canonical if entry.respond_to?(:canonical)
      return entry.key?('canonical') ? entry['canonical'] : entry[:canonical] if entry.respond_to?(:[])
      nil
    end

    def validate_each_entry(record, attribute, entries)
      entries.each do |entry|
        path = path_for(entry)
        if path.blank?
          record.errors.add(attribute, message_for(:blank))
        elsif !PATH_FORMAT.match?(path)
          record.errors.add(attribute, message_for(:invalid_format, path: path))
        elsif reserved_prefix?(path)
          record.errors.add(attribute, message_for(:reserved_prefix, path: path))
        end
      end
    end

    def reserved_prefix?(path)
      normalized = normalized_path(path)
      Hyrax.config.reserved_redirect_prefixes.any? do |prefix|
        normalized == prefix || normalized.start_with?("#{prefix}/")
      end
    end

    def validate_intra_record_uniqueness(record, attribute, entries)
      grouped = entries.each_with_object({}) do |entry, acc|
        path = path_for(entry)
        next if path.blank?
        canonical = normalized_path(path)
        next if canonical.blank?
        (acc[canonical] ||= []) << path
      end
      grouped.each_value do |paths|
        next unless paths.size > 1
        record.errors.add(attribute, message_for(:intra_record_duplicate, path: paths.first))
      end
    end

    def validate_global_uniqueness(record, attribute, entries)
      except_id = record.try(:id)
      entries.each do |entry|
        path = path_for(entry)
        next if path.blank?
        next unless Hyrax::RedirectsLookup.taken?(normalized_path(path), except_id: except_id)
        record.errors.add(attribute, message_for(:already_taken, path: path))
      end
    end

    def normalized_path(path)
      Hyrax::RedirectPathNormalizer.call(path)
    end

    def validate_at_most_one_canonical(record, attribute, entries)
      canonical_count = entries.count { |entry| canonical_for(entry) }
      return if canonical_count <= 1
      record.errors.add(attribute, message_for(:multiple_canonical))
    end

    def message_for(key, **interpolations)
      I18n.t(key, scope: 'errors.messages.redirect', **interpolations)
    end

    # Reform forms wrap the underlying resource and use method_missing to
    # forward attribute reads. We can't just call `record.respond_to?(:redirects)`
    # because Reform's method_missing returns truthy for missing methods.
    # Probe the actual underlying resource through the form's `__getobj__`
    # (Reform's accessor for the wrapped object) when present.
    def record_supports_redirects?(record)
      target = record.respond_to?(:__getobj__) ? record.__getobj__ : record
      target.respond_to?(:redirects)
    end
  end
end
