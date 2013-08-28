require 'rdf'
require 'cgi'

class AuthoritiesController < ApplicationController
  def query
    s = params.fetch("q", "")
    if (params[:term]=="location")
      hits = GeoNamesResource.find_location(s)
    else
      hits = LocalAuthority.entries_by_term(params[:model], params[:term], s) rescue []
    end
    render :json=>hits
  end
end
