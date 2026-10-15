# frozen_string_literal: true

module Hyrax
  ##
  # A Blacklight `values:` lambda showing a controlled term's label where one is
  # indexed, and its stored id otherwise.
  #
  # A lambda rather than pointing the field at the label key: Blacklight drops a
  # field whose Solr key is absent, so repointing would blank the row for every
  # work indexed before the label fields existed. `field:` cannot express the
  # fallback either — it reaches `document.fetch`, which takes a single key.
  class ControlledVocabularyFieldValues
    def self.to_proc
      lambda do |field_config, document, _view_context|
        key = field_config.field.to_s
        document.fetch(label_key(key), nil).presence || document.fetch(key, nil)
      end
    end

    ##
    # The prefix every label companion of `field` shares: `license` ->
    # `license_label`. Used to find them without assuming a suffix, since a
    # property may declare any index key.
    #
    # @param field [String, Symbol] an attribute name
    # @return [String]
    def self.label_prefix(field)
      "#{field}_label"
    end

    ##
    # `license_tesim` -> `license_label_tesim`.
    #
    # The suffix has to stay last: Solr resolves these through dynamic field
    # rules keyed on the suffix, so `license_sim_label` is not a field at all and
    # indexing it fails the whole document with a 400.
    #
    # A profile declaring a literal `<name>_label` property would collide with
    # the companion field of `<name>`.
    #
    # @param key [String, Symbol] a solr index key
    # @return [String] the key its labels are written to
    def self.label_key(key)
      base, _, suffix = key.to_s.rpartition('_')
      return key.to_s if base.blank? || suffix.blank?

      "#{base}_label_#{suffix}"
    end
  end
end
