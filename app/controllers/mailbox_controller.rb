class MailboxController < ApplicationController
  before_filter :authenticate_user!

  def index
    if User.current
      inbox = User.current.mailbox.inbox
      @messages = inbox
    else
      @messages =[]
    end 
  end

  def delete_all     
     User.current.mailbox.inbox.each do |msg|
        delete_message(msg)
     end
     empty_trash(User.current)
     redirect_to mailbox_path
  end

  def delete
    if (User.current)
      msg = Conversation.find(params[:uid])
      puts "************* User = #{msg.participants[0].login}.inspect"
      if (msg.participants[0] == User.current) || (msg.participants[1] == User.current)
         delete_message(msg)
         empty_trash(msg.participants[0])
      end
   else 
      flash[:alert] = "You do not have privileges to delete the notification..."
   end
   redirect_to mailbox_path
  end

private 

  def delete_message (msg)
      msg.move_to_trash(msg.participants[0])
      msg.move_to_trash(msg.participants[1])
  end
  
  def empty_trash (user)
    user.mailbox.trash.each { |conv| conv.messages.each {|notify| notify.receipts.each { |receipt| receipt.delete}; notify.delete}; conv.delete}
  end

end