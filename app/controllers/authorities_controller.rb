require 'rdf'
require 'cgi'

class AuthoritiesController < ApplicationController
  def query
    s = params.fetch("q", "")
    hits =
      if params[:term] == "location"
        GeoNamesResource.find_location(s)
      else
        begin
          LocalAuthority.entries_by_term(params[:model], params[:term], s)
        rescue
          []
        end
      end
    render json: hits
  end
end
