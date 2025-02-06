# frozen_string_literal: true
module ActiveRecord
  module TestFixtures
    def fixture_path
      fixture_paths[0]
    end
  end
end
