module PersonalizationHelper

  DEFAULT_USER_ATTRIBUTES = ['full_name', 'affiliation', 'photo']

  # Helper methods to retrieve information from the user attributes
  # 
  # == get_full_name_from_login
  #
  # Given a login, returns a string concatenating first_name and last_name
  #
  # == get_affiliation_from_login 
  #
  # Given a login, returns a string
  #
  # == get_photo_from_login
  #
  # Given a login, returns a string representing either a path or a url pointing to an image file
  DEFAULT_USER_ATTRIBUTES.each do |m|
    class_eval <<-EOC
      def #{m}_from_login login
        get_user_attribute(login, '#{m}')
      end
    EOC
  end

  # Creates an image tag with the user#photo attribute as the source
  # @param [string] login the login of the user
  # @return an html image tag or an empty string
  def user_photo_tag login
    path = photo_from_login login
    path == "" ? "" : image_tag(path)
  end

  private

  # Retrieves an attribute from the user
  # @param [string] login the login of the user
  # @param [string] the name of the attribute: out of the box values are first_name, last_name, full_name, affiliation, and photo
  def get_user_attribute login, attribute
    user = User.find_by_login(login) 
    user.nil? ? "" : user.send(attribute.to_sym)
  end

end
