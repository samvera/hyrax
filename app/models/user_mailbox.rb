class UserMailbox
  attr_reader :user

  def initialize(user)
    @user = user
  end

  def inbox
    messages = user.mailbox.inbox
    messages.each { |m| m.mark_as_read(user) }
  end

  def delete_all
    user.mailbox.inbox.each do |msg|
      delete_message(msg)
    end
    empty_trash(user)
  end

  def destroy(message_id)
    msg = Mailboxer::Conversation.find(message_id)
    return "You do not have privileges to delete the notification..." unless msg.participants.include? user
    delete_message(msg)
    empty_trash(msg.participants[0])
    nil
  end

  private

    def delete_message(msg)
      msg.move_to_trash(msg.participants[0])
      msg.move_to_trash(msg.participants[1])
    end

    def empty_trash(user)
      user.mailbox.trash.each do |conv|
        conv.messages.each do |notify|
          notify.receipts.each(&:delete)
          notify.delete
        end
        conv.delete
      end
    end
end
