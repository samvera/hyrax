module Hyrax
  module Analytics
    module Google
      module Page
        extend Legato::Model

        metrics :pageviews
        dimensions :page_path, :page_title

        filter(:works) {|page_path_level1| contains(:pagePathLevel1, 'works')}

      end
    end
  end
end