require 'rdf'

class AuthoritiesController < ApplicationController
  def query
    s = params.fetch("q", "")
    hits = LocalAuthority.entries_by_term(params[:model], params[:term], s) rescue hits = []
    render :json=>hits
  end
end
