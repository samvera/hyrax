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


  private
 

end
