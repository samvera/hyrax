class SessionsController < Devise::SessionsController
  include CurationConcerns::ThemedLayoutController
  with_themed_layout '1_column'
end
