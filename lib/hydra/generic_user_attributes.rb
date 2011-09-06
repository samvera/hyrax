module Hydra::GenericUserAttributes

  USER_ATTRIBUTES = ['first_name','last_name','full_name','affiliation','photo']

  attr_writer :user_attributes

# Creates accessor methods for attributes defined in USER_ATTRIBUTES which return a string
  USER_ATTRIBUTES.each do |m|
    class_eval <<-EOM
      def #{m}
        get_user_attribute "#{m}"
      end
    EOM
  end

  # Retrieves the UserAttribute object for the user.  This defaults to the packaged ActiveRecord object, but can be overwritten with #user_attributes=
  # @return an object containing the user's attributes.  If providing a localized class, be sure to include the default attributes of first_name, last_name, full_name, affiliation and photo.
  def user_attributes
    @user_attributes ||= user_attribute
  end

  private

  def user_attribute
   UserAttribute.find_by_user_id(self.id)
  end

  def get_user_attribute attr_name
    attr_name = attr_name.to_sym if attr_name.is_a? String
    user_attributes.nil? ? "" :  user_attributes.send(attr_name)
  end
 

end
