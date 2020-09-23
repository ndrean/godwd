class Api::V1::ItinariesController < ApplicationController
    def index
        itinaries = Itinary.all
        if stale?(itinaries)
            render json: itinaries
        end
    end
end