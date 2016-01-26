class Hydra::PermissionsSolrDocument < SolrDocument
  def under_embargo?
    #permissions = permissions_doc(params[:id])
    embargo_key = Hydra.config.permissions.embargo.release_date
    if self[embargo_key]
      embargo_date = Date.parse(self[embargo_key].split(/T/)[0])
      return embargo_date > Date.parse(Time.now.to_s)
    end
    false
  end
end
