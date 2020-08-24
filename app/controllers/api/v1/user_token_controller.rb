class Api::V1::UserTokenController < Knock::AuthTokenController
    # can't verify csrfToken =>
    skip_before_action :verify_authenticity_token, raise: false

    def auth_params
      params.require(:auth).permit( :access_token, :email,  :password)
    end
end