ActionMailer::Base.smtp_settings = {
  address: 'smtp.mailgun.org',
  port: 587,
  domain: ENV['DOMAIN_NAME'],
  user_name: ENV['SMTP_USER_NAME'],
  password: ENV['MAIL_APP_PASSWORD'],
  authentication: :plain,
  enable_starttls_auto: true
}