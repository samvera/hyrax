module Sufia
  module BlacklightOverride
    def render_bookmarks_control?
      false
    end

   def url_for_document doc, options = {}
     [sufia, doc]
   end
  end
end
