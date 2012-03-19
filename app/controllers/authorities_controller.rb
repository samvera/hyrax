require 'rdf'

class AuthoritiesController < ApplicationController
  def query
    s = params.fetch(:q, "")
    context = "#{params[:model].singularize}__#{params[:term]}"
    klass = params[:model].classify.concat("RDFDatastream").constantize
    repo = klass.repo
    hits = []
    if repo.has_context?(context)
      repo.query(:predicate => RDF::SKOS.prefLabel, :context => RDF::URI(context)) do |stmt|
        next unless s.empty? or stmt.object.to_s.start_with? s
        hits << {:uri => stmt.subject.to_s, :label => stmt.object.to_s}
      end
    end
    render :json=>hits
  end
end
