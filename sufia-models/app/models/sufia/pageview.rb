module Sufia
  class Pageview
    extend Legato::Model

    metrics :pageviews
    dimensions :date
    filter :for_path, &lambda { |path| contains(:pagePath, path) }
  end
end
