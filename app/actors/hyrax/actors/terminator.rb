# frozen_string_literal: true
module Hyrax
  module Actors
    # This is always the last middleware on the actor middleware stack.
    class Terminator
      def create(_env)
        true
      end

      def update(_env)
        true
      end

      def destroy(_env)
        true
      end
    end
  end
end
