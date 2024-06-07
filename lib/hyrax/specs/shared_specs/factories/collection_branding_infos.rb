# frozen_string_literal: true
FactoryBot.define do
  factory :collection_branding_info do
    collection_id { "1" }
    role { "banner" }
    local_path { "/fake/path/to/banner.png" }
    alt_text { "This is the banner" }
    target_url { "http://example.com/" }
    height { "" }
    width { "" }
  end
end
