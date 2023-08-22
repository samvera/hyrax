# Generated via
#  `rails generate hyrax:work GenericWork`
class GenericWork <Hyrax::Work
  include Hyrax::Schema(:basic_metadata)

  # Change this to restrict which works can be added as a child.
  # self.valid_child_concerns = []
  # TODO validate?
  # validates :title, presence: { message: 'Your work must have a title.' }

end
