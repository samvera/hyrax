require 'rdf'

class AuthoritiesController < ApplicationController
  def query
    s = params.fetch("q", "")
    term = DomainTerm.where(:model => params[:model], :term => params[:term]).first
    hits = []
    if term
      authorities = term.local_authorities.collect(&:id).uniq      
      sql = LocalAuthorityEntry.where("local_authority_id in (?)", authorities).where("label like ?", "%#{s}%").select("label, uri").to_sql
      LocalAuthorityEntry.find_by_sql(sql).each do |hit|
        hits << {:uri => hit.uri, :label => hit.label}
      end
    end
    render :json=>hits
  end
end
