class Api::V1::ItinariesController < ApplicationController
    def index
        render json: Itinary.all
    end
end