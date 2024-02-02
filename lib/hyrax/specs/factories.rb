# Given that Hyrax is a large Engine; lots of controllers and models, it makes sense to expose the
# factories of the test suite to the downstream application (e.g. Hyku).
#
# That way, we can create extensions of those factories in the downstream application.
Hyrax::Engine.root.glob("spec/factories").each do |path|
  require path
end
