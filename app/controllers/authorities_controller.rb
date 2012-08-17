require 'rdf'
require 'cgi'

class AuthoritiesController < ApplicationController
  def query
    s = params.fetch("q", "")
    if (params[:term]=="location")
      hits = GeoNamesResource.find_loaction(s) 
    else 
      hits = LocalAuthority.entries_by_term(params[:model], params[:term], s) rescue hits = []
    end
    render :json=>hits
  end
end
