# class RegisterJob < ApplicationJob
#   queue_as :mailers

#   def perform(fb_user_email, fb_user_confirm_token)
#     UserMailer.register(fb_user_email, fb_user_confirm_token).deliver
#   end
# end