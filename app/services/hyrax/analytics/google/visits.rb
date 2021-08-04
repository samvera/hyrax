module Hyrax
  module Analytics
    module Google
      module Visits
        extend Legato::Model
        # metrics :visitors, :new_visits
        # dimensions :session_count, :date
        dimensions :user_type
        metrics :sessions
      end
    end
  end
end

