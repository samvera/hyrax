module Sufia
  module Admin
    class FeaturesController < Flip::FeaturesController
      before_action do
        authorize! :manage, Sufia::Feature
      end
    end
  end
end
