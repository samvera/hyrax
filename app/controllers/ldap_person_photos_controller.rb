class LdapPersonPhotosController < ApplicationController 

  def show
    person = Ldap::Person.new(params[:id])
    send_data person.photo, :type => "image/jpeg", :file_name => person.computing_id, :disposition => 'inline' unless !person.has_photo?
    return
  end
  
end
