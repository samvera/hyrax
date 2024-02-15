# Given that Hyrax is a large Engine; lots of controllers and models, it makes sense to expose the
# factories of the test suite to the downstream application (e.g. Hyku).
#
# That way, we can create extensions of those factories in the downstream application.

[
  "spec/support/simple_work"
].each do |partial|
  require Hyrax::Engine.root.join(partial).to_s
end

Hyrax::Engine.root.glob("spec/factories/**/*.rb").each do |path|
  begin
    require path.to_s
  rescue FactoryBot::DuplicateDefinitionError => e
    # It's alright maybe downstream defined these
    Rails.logger.warn(e.message)
  end
end
