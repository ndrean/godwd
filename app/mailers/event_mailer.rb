class EventMailer < ApplicationMailer
  default from: ENV['SMTP_USER_NAME']
  
  def invitation(p_email, event_ID)
    @p_email = p_email
    @event = Event.find(event_ID)
    return if @event.nil? || p_email.nil?
    mail(to: @p_email,  subject: "Invitation to a downwind event")
  end

  def demand(u_email, owner_email, itinary_id, token)
    # we will pass the following isntance varialbes to the view of the mail:
    @user = u_email
    @owner = owner_email
    @token = token
    @itinary = Itinary.find(itinary_id)

    # we will attach #{@params.to_query} as a query string to the url
    # it contains a token already saved in the db to find the event
    @params= {name:owner_email, ptoken:token, user:u_email, itinary:itinary_id}
    mail(to: @owner, subject: "Demand to join")
  end
end

# NOTE:
# @params.to_query= {name:owner_email, ptoken:token, user:u_email, itinary:itinary_id}.to_query
# gives the following result:
# name=#{@owner}&ptoken=#{@token}&user=#{@user}&itinary=#{@itinary.id}
# that will be attached to the url after the ? (see '#views/event_mailer/demand')