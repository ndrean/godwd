class Api::V1::UsersController < ApplicationController
  before_action( :authenticate_user, only: [ :destroy, :profile] )

  def fb_params
    # expires_in 12.hours, public: true
    render json: {
      "fb_id": Rails.application.credentials.fb[:fb_id],
      "fb_secret": Rails.application.credentials.fb[:fb_secret]
    }
  end

  def cl_params
    expires_in 24.hours, public: true
    render json:{
      "CLOUD_NAME": Rails.application.credentials.CL[:CLOUD_NAME]
      
    }
  end
  #"CL_API_Secret": Rails.application.credentials.CL[:API_SECRET],
  #"CL_API_KEY": Rails.application.credentials.CL[:API_KEY]

  # endpoint check user
  def profile
    # expires_in 4.hours
    render json: current_user
  end

  def find_user
    user = User.find_by(email: params[:user][:email])
    if user && stale?(user)
      render json: user
    else
      render json: errors
    end
  end

  def find_create_with_fb   
    fb_user = User.find_or_create_by(uid: user_params['uid']) do |user|
      user.email = user_params['email']
      user.password = SecureRandom.urlsafe_base64.to_s
      user.uid = user_params['uid']
      user.save
      user.access_token = Knock::AuthToken.new(payload: {sub: user.id}).token
      user.save
    end

    if fb_user.confirm_token.blank? && !fb_user.confirm_email
      fb_user.confirm_token = SecureRandom.urlsafe_base64.to_s
      UserMailer.register(fb_user.email, fb_user.confirm_token).deliver_later
      fb_user.save
      return render json: fb_user, status: 200
    end

    if fb_user.confirm_email
      fb_user.access_token = Knock::AuthToken.new(payload: {sub: fb_user.id}).token
      fb_user.save
      return render json: fb_user, status: 202
    end

    if !fb_user.confirm_email && fb_user.confirm_token  
      logger.debug "............Wait for email confirmation"
      return render json: {status: 201}
    end
  end

  # POST '/api/v1/CreateUser'
  def create_user
    return render json: { status: :not_acceptable }  if !user_params[:password]
    user = User.find_by(email: user_params[:email])
    logger.debug "..........#{user}"
    user.password = user_params[:password] if user
    user = User.create(user_params) if !user
    # if the user has no 'confirm_token', set one and send a mail with it for him to click
    if user.confirm_token.blank? #&& !user.confirm_email
      user.confirm_token = SecureRandom.urlsafe_base64.to_s
      user.save # save it in db for method 'confirmed_email to find him with the token
      UserMailer.register(user.email, user.confirm_token).deliver_later
    end
    # if the user has clicked on mail, the method 'confirmed_mail' has set confirm_mail=true and confirm_token=nil
    if user.confirm_email && user.confirm_token.blank?
      return render json: user, status: 201
    end

    render json: { status: 401 }
  end
    
  # GET '/api/v1/ConfirmDemand'
  # token sent via link via mail from user to confirm register
  def confirmed_email
    user = User.find_by(confirm_token: params[:mail_token])
    if user
      user.confirm_token = nil
      user.confirm_email = true
      return user.save
    end

    render json: { status: 401 }
  end


  def index
    users = User.all.to_json
     if stale?(users)
      render json: users
     end
  end

  # GET 'api/v1//users/:id'
  def show
    user = User.find(params[:id])
    render json: user
  end


  # DELETE 'api/v1/users/:id'
  def destroy
    user = User.find(params[:id])
    if user == current_user
      user.destroy
    end
  end

  private
    def auth_params
      params.require(:auth).permit( :email, :password_digest, :access_token, :uid)
    end

    def user_params
      params.require(:user).permit(:email, :name, :password, :password_digest, :access_token, :uid)
    end 
    
end
  