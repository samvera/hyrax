class MailboxController < ApplicationController
  before_filter :authenticate_user!

  def index
    if user_signed_in?
      @messages = current_user.mailbox.inbox
      @messages.each{|m| m.mark_as_read(current_user)}
    else
      @messages =[]
    end 
  end

  def delete_all     
     current_user.mailbox.inbox.each do |msg|
        delete_message(msg)
     end
     empty_trash(current_user)
     redirect_to sufia.notifications_path
  end

  def destroy
    if current_user
      msg = Mailboxer::Conversation.find(params[:id])
      if (msg.participants[0] == current_user) || (msg.participants[1] == current_user)
         delete_message(msg)
         empty_trash(msg.participants[0])
      end
    else 
      flash[:alert] = "You do not have privileges to delete the notification..."
    end
    redirect_to sufia.notifications_path
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
