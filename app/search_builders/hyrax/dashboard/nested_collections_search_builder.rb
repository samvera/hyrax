# frozen_string_literal: true
module Hyrax
  module Dashboard
    # Responsible for searching for collections of the same type that are not the given collection
    class NestedCollectionsSearchBuilder < ::Hyrax::CollectionSearchBuilder
      # @param access [Symbol] :edit, :read, :discover - With the given :access what all can
      # @param collection [::Collection]
      # @param scope [Object] Typically a controller that responds to #current_ability, #blackligh_config
      # @param nesting_attributes [NestingAttributes] an object encapsulating nesting attributes of the collection
      # @param nest_direction [Symbol] (:as_parent or :as_child) the direction we are adding nesting to this collection
      def initialize(access:, collection:, scope:, nesting_attributes:, nest_direction:)
        super(scope)
        @collection = collection
        @discovery_permissions = extract_discovery_permissions(access)
        @nesting_attributes = nesting_attributes
        @nest_direction = nest_direction
      end

      # Override for Hydra::AccessControlsEnforcement
      attr_reader :discovery_permissions
      self.default_processor_chain += [:with_pagination, :show_only_other_collections_of_the_same_collection_type]

      def with_pagination(solr_parameters)
        solr_parameters[:rows] = 1000
      end

      def show_only_other_collections_of_the_same_collection_type(solr_parameters)
        solr_parameters[:fq] ||= []
        solr_parameters[:fq] += [
          "-" + Hyrax::SolrQueryBuilderService.construct_query_for_ids([limit_ids]),
          Hyrax::SolrQueryBuilderService.construct_query(Hyrax.config.collection_type_index_field => @collection.collection_type_gid)
        ]
        solr_parameters[:fq] += limit_clause if limit_clause # add limits to prevent illegal nesting arrangements
      end

      private

      def limit_ids
        # exclude current collection from returned list
        limit_ids = [@collection.id]
        # cannot add a parent that is already a parent
        limit_ids += @nesting_attributes.parents if @nesting_attributes.parents && @nest_direction == :as_parent
        limit_ids
      end

      # remove collections from list in order to to prevent illegal nesting arrangements
      def limit_clause
        case @nest_direction
        when :as_parent
          eligible_to_be_a_parent
        when :as_child
          eligible_to_be_a_child
        end
      end

      # To be eligible to be a parent collection of child "Collection G":
      # 1) cannot have any pathnames containing Collection G's ID
      # 2) cannot already be Collection G's direct parent
      # => this is handled through limit_ids method
      def eligible_to_be_a_parent
        # Using a !lucene query allows us to get items using a wildcard query, a feature not supported via AF query builder.
        ["-_query_:\"{!lucene df=#{Samvera::NestingIndexer.configuration.solr_field_name_for_storing_pathnames}}*#{@collection.id}*\""]
      end

      # To be eligible to be a child collection of parent "Collection F":
      # 1) Cannot have any pathnames containing any of Collection F's pathname or ancestors
      # 2) cannot already be Collection F's direct child
      def eligible_to_be_a_child
        exclude_path = []
        exclude_path << exclude_if_paths_contain_collection
        exclude_path << exclude_if_already_parent
      end

      def exclude_if_paths_contain_collection
        # 1) Exclude any pathnames containing any of Collection F's pathname or ancestors
        array_to_exclude = [] + @nesting_attributes.pathnames unless @nesting_attributes.pathnames.nil?
        array_to_exclude += @nesting_attributes.ancestors unless @nesting_attributes.ancestors.nil?
        # build a unique string containing all of Collection F's pathnames and ancestors
        exclude_list = ""
        array_to_exclude&.uniq&.each do |element|
          exclude_list += ' ' unless exclude_list.empty?
          exclude_list += element.to_s
        end
        # Using a !lucene query allows us to get items which match any individual element
        # from the list. Building the query via the AF builder created a !field query which
        # only searches the field for an exact string and doesn't allow an "OR" connection
        # between the elements.
        return "-_query_:\"{!lucene q.op=OR df=#{Samvera::NestingIndexer.configuration.solr_field_name_for_storing_pathnames}}#{exclude_list}\"" unless exclude_list.empty?
        ""
      end

      def exclude_if_already_parent
        # 2) Exclude any of Collection F's direct children
        "-" + ActiveFedora::SolrQueryBuilder.construct_query(Samvera::NestingIndexer.configuration.solr_field_name_for_storing_parent_ids => @collection.id)
      end
    end
  end
end
