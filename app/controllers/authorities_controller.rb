require 'rdf'

class AuthoritiesController < ApplicationController
  def query
    s = params.fetch(:q, "")
    term = DomainTerm.find(params)
    hits = []
    if term
      authorities = term.local_authorities.collect { |a| a.local_authority_id }
      sql = LocalAuthorityEntry.where("local_authority_id = ?",
  authorities).where("label like ?", "%#{s}%").select("label, uri").to_sql
      LocalAuthorityEntry.find_by_sql(sql).each do |hit|
        hits << {:uri => hit.uri, :label => hit.label}
      end
    end
    render :json=>hits
  end
end
