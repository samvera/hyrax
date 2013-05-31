module Sufia
  module GenericFile
    module WebForm

      # override this method if you need to initialize more complex RDF assertions (b-nodes)
      def initialize_fields
        terms_for_editing.each do |key|
          # if value is empty, we create an one element array to loop over for output 
          self[key] = [''] if self[key].empty?
        end
      end

    end
  end
end
