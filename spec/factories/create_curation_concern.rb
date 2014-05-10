def FactoryGirl.create_curation_concern(factory_name, user, override_attributes = {})
  FactoryGirl.create(factory_name, override_attributes.merge(user: user))
end
