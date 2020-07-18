# frozen_string_literal: true
module Hyrax
  module SolrDocument
    ##
    # Decorates an object responding to `#id` with an `#ordered_member_ids` method.
    #
    # @note this decorator is intended for use with data representations other
    #   than the core model objects, as an alternative to a direct query of the
    #   canonical database. for example, it can be used with `SolrDocument` to
    #   quickly retrieve member order in a way that is compatible with the
    #   fast access required in Blacklight's search contexts.
    #
    # @example
    #   base_document = SolrDocument.new(my_work.to_solr)
    #   solr_document = Hyrax::SolrDocument::OrderedMembers.decorate(base_document)
    #
    #   solr_document.ordered_member_ids # => ['abc', '123']
    #
    class OrderedMembers < Hyrax::ModelDecorator
      ##
      # @note the purpose of this method is to provide fast access to member
      #   order. currently this is achieved by accessing indexed list proxies
      #   from Solr. however, this strategy may change in the future.
      #
      # @return [Enumerable<String>] ids in the order of their membership,
      #   only includes ids of ordered members.
      def ordered_member_ids
        return [] if id.blank?
        @ordered_member_ids ||= query_for_ordered_ids
      end

      private

      def query_for_ordered_ids(limit: 10_000,
                                proxy_field: 'proxy_in_ssi',
                                target_field: 'ordered_targets_ssim')
        Hyrax::SolrService
          .query("#{proxy_field}:#{id}", rows: limit, fl: target_field)
          .flat_map { |x| x.fetch(target_field, nil) }
          .compact
      end
    end
  end
end
