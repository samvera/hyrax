class GeoNamesResource < ActiveResource::Base
  self.site = "http://api.geonames.org/"
  self.element_name = "searchJSON"
  self.collection_name = "searchJSON"

  def self.collection_path(prefix_options = {}, query_options = nil)
    super(prefix_options, query_options).gsub(/\.json|\.xml/, "")
  end

  def self.instantiate_collection(collection, original_params = {}, prefix_options = {})
    col = super(collection["geonames"], original_params, prefix_options)
    col.map! { |item| { label: item.name + (item.adminName1 ? ", " + item.adminName1 : "") + ", " + item.countryName, value: item.name + (item.adminName1 ? ", " + item.adminName1 : "") + ", " + item.countryName } }
  end

  def self.find_location(location)
    GeoNamesResource.find(:all, params: { q: location, username: Sufia.config.geonames_username, maxRows: 10 })
  end
end
