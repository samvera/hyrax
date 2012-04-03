require 'rdf'

class AuthoritiesController < ApplicationController
  def query
    s = params.fetch(:q, "")
    term = DomainTerm.find(params)
    if term
      # this is very wrong
      term.local_authority.entries do |entry|
        next unless s.empty? or entry.label.start_with? s
        hits << {:uri => entry.uri, :label => entry.label}
      end
    end
    render :json=>hits
  end
end
