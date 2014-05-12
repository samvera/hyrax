class SessionsController < Devise::SessionsController
  include Worthwhile::ThemedLayoutController
  with_themed_layout '1_column'
end
