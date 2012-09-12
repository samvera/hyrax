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
     msg = Conversation.find(params[:uid])
     delete_message(msg)
     empty_trash(msg.participants[0])
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