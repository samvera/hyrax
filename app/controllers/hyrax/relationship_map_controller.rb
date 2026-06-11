# frozen_string_literal: true
module Hyrax
  ##
  # PROTOTYPE (Enact "patch cables" relationship map).
  #
  # Builds an interactive graph of works and the typed relationships between
  # them, read from the Solr fields the Object Handling Spec v0.2 §3.5
  # proposes on the item document:
  #   * +relationship_target_ids_ssim+ / +relationship_types_ssim+ (flat,
  #     for indexability), and
  #   * +relationship_json_ss+ (a JSON blob carrying target + type + the
  #     curatorial +note+, since the flat fields can't pair a note per edge).
  #
  # +?focus=<id>+ centres the map on one work — the view a "Relationship map"
  # button on a work show page opens. Not production code; the real build is
  # the first-class ItemRelationship model + deposit UI (still in co-design).
  class RelationshipMapController < ApplicationController
    def show
      docs = work_documents
      ids  = docs.map { |d| d['id'] }.to_set
      @graph = {
        nodes: docs.map { |d| node_for(d) },
        links: docs.flat_map { |d| links_for(d) }.select { |l| ids.include?(l[:target]) }
      }
      @focus = params[:focus].to_s
      render layout: false
    end

    private

    def work_documents
      models = Hyrax.config.registered_curation_concern_types.presence || %w[Monograph GenericWork]
      Hyrax::SolrQueryService.new
                             .with_field_pairs(field_pairs: { 'has_model_ssim' => models }, join_with: 'OR')
                             .accessible_by(ability: current_ability)
                             .solr_documents(rows: 1_000)
    end

    def node_for(doc)
      model = Array(doc['has_model_ssim']).first.to_s
      { id: doc['id'],
        label: Array(doc['title_tesim']).first || 'Untitled',
        type: model,
        closed: doc['visibility_ssi'] == 'restricted',
        path: model.present? ? "/concern/#{model.tableize}/#{doc['id']}" : "/#{doc['id']}" }
    end

    # Prefer the JSON blob (carries the note); fall back to the flat fields.
    def links_for(doc)
      if doc['relationship_json_ss'].present?
        Array(JSON.parse(doc['relationship_json_ss'])).map do |r|
          { source: doc['id'], target: r['target_id'], rel: r['relation_type'], note: r['note'] }
        end
      else
        targets = Array(doc['relationship_target_ids_ssim'])
        types   = Array(doc['relationship_types_ssim'])
        targets.each_with_index.map do |t, i|
          { source: doc['id'], target: t, rel: types[i] || 'juxtaposed-with', note: nil }
        end
      end
    rescue JSON::ParserError
      []
    end
  end
end
