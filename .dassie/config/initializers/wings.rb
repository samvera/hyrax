Rails.application.config.after_initialize do
  Wings::ModelRegistry.register(GenericWorkResource, GenericWork)
end
