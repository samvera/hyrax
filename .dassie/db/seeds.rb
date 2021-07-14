# This line loads the Hyrax seed
# Hyrax::Engine.load_seed

# visibility options are
# "open"
# "authenticated"
# "embargo"
# "lease"
# "restricted"


13.times do |i|
	title = "Work #{i}"
	work = GenericWork.create(title:[title])
    work.description = ["A description for Work #{i}"]
    work.visibility = "open"
    work.resource.creator = ["user1"]
    work.save!

end
