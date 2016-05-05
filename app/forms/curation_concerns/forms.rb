module CurationConcerns
	 # This will be the module for containing forms
	 # @since 0.14.0
	# Forms are a type of data structures that include validation that leverage hydra editor 
	# capabilities. Their purpose is to allow users to edit and save objects based on models.
	# The impetus for their creation was to remove validation from models, and perhaps 
	# demultiplex fields from one form to multiple objects. A form must define the model
	# it uses and attributes it manipulates. It may include default values and define required
	# required fields. They are ruby objects that are typically instantiated by the controller 
	# to facilitate user creation, editing, or deleting of an object. They can also be used to
	# sanitize attributes passed along to actors, as they are in curation concerns.
	module Forms
	end
end
