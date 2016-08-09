module TestViewHelpers
  extend ActiveSupport::Concern

  included do
    before do
      view.send(:extend, CurationConcerns::MainAppHelpers)
      view.send(:extend, CatalogHelper)
    end
  end
end
