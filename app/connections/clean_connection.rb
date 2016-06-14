# This stands in for ActiveFedora::CleanConnection. It behaves the same way,
# but it doesn't clear the has_model assertion
class CleanConnection < SimpleDelegator
  def get(*args)
    result = __getobj__.get(*args) do |req|
      prefer_headers = Ldp::PreferHeaders.new(req.headers["Prefer"])
      prefer_headers.omit = prefer_headers.omit | omit_uris
      req.headers["Prefer"] = prefer_headers.to_s
    end
    result
  end

  private

    def omit_uris
      [
        ::RDF::Vocab::Fcrepo4.ServerManaged,
        ::RDF::Vocab::LDP.PreferContainment,
        ::RDF::Vocab::LDP.PreferEmptyContainer,
        ::RDF::Vocab::LDP.PreferMembership
      ]
    end
end
