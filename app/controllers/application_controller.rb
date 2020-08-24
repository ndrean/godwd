class ApplicationController < ActionController::API
    include Knock::Authenticable
    # applicable to all controllers

    def routing_error(error = 'Routing error', status = :not_found, exception=nil)
        render json: {errors: "Routing error"}, status: 404
    end
    
end
