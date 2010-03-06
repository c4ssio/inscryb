class PlaceMailer < ActionMailer::Base

  def question(message,email)
    @recipients = email
    @from = 'cassio.paesleme@gmail.com'
    @subject = "new message"
    @sent_on = Time.now
    @body = message
  end
  
end
