class UserMailer < ApplicationMailer
    default from: ENV['SMTP_USER_NAME']
    

    def register(user_email, user_confirmation_token)
        @user_email = user_email
        @user_confirmation_token = user_confirmation_token
        mail(to: @user_email,  subject: "Confirm your registration")
    end

    def accept(current_user_email, owner_email, itinary_id)
        @current = current_user_email
        @owner = owner_email
        @itinary = Itinary.find(itinary_id)
        mail(to: @current, subject: 'Demand Accepted!' )
    end
end