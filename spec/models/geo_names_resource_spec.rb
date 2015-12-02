require 'spec_helper'

describe GeoNamesResource, type: :model do
  before do
    state = {
      "totalResultsCount" => 1, "geonames" => [{
        "countryId" => "1327865", "adminCode1" => "11", "countryName" => "Myanmar [Burma]", "fclName" => "country, state, region,...", "countryCode" => "MM", "lng" => "98", "fcodeName" => "first-order administrative division", "toponymName" => "Shan State", "fcl" => "A", "name" => "Shan State", "fcode" => "ADM1", "geonameId" => 1_297_099, "lat" => "22", "adminName1" => "Shan", "population" => 5_815_384
      }]
    }
    ActiveResource::HttpMock.respond_to do |mock|
      mock.get "/searchJSON?maxRows=10&q=State&username=", {}, state.to_json
    end
  end
  it "finds locations" do
    hits = described_class.find_location("State")
    expect(hits).not_to be_nil
  end
end
