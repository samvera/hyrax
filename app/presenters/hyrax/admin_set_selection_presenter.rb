# frozen_string_literal: true
module Hyrax
  ##
  # @api public
  # @since 3.1.0
  #
  # Presents select options for admin sets.
  #
  # @note this supersedes the older +Hyrax::AdminSetOptionsPresenter+, which
  #   actied more like a "service" sending database queries to Solr and
  #   ActiveRecord.  this version seeks only to present the input data and
  #   relies on its caller to pass in the right data.
  class AdminSetSelectionPresenter
    ##
    # @param [Array<#id>]
    def initialize(admin_sets:)
      @admin_sets = admin_sets
    end

    ##
    # @return [Array<Array<String, String, Hash>>] an array suitable for  a form
    #   input `collection:` parameter. it should contain a label, an id, and a
    #   hash of HTML5  data attributes.
    def select_options
      @admin_sets.map do |admin_set|
        case admin_set
        when OptionsEntry
          admin_set.result
        else
          OptionsEntry.new(admin_set: admin_set).result
        end
      end
    end

    ##
    # @api public
    class OptionsEntry
      ##
      # @!attribute [rw] admin_set
      #   @return [AdministrativeSet, SolrDocument]
      attr_accessor :admin_set

      ##
      # @param [AdministrativeSet, SolrDocument] admin_set
      def initialize(admin_set:)
        @admin_set = admin_set
      end

      ##
      # @return [Array<String, String, Hash>]
      def result
        [label, id, data]
      end

      ##
      # @return [String]
      def label
        Array(admin_set.title).first || admin_set.to_s
      end

      ##
      # @return [String]
      def id
        admin_set.id.to_s
      end

      ##
      # @return [Hash{String => Object}]
      def data
        {}.tap do |data|
          data['data-release-no-delay'] = true
          data['data-visibility'] = Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE
        end
      end
    end
  end
end
