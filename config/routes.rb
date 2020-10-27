  Rails.application.routes.draw do
  
    namespace :api do
      namespace :v1 do
        
        #knock
        post '/getUserToken',     to: 'user_token#create'

        #credentials passed to front end
        # get '/fbParams',          to: 'users#fb_params'
        # get '/CLParams',          to: 'users#cl_params'

        resources :users, only: [ :index, :show]
        get '/profile',           to: 'users#profile'
        post '/findUser',         to: 'users#find_user'
        post '/createUser',       to: 'users#create_user'
        get '/mailconfirmation',  to: 'users#confirmed_email'
        post '/findCreateFbUser', to: 'users#find_create_with_fb'

        resources :events, only: [ :index, :create, :update, :destroy, :show]
        post '/pushDemand',       to:'events#receive_demand'
        get 'confirmDemand',      to: 'events#confirm_demand'
        
        get 'itinaries',          to: 'itinaries#index'

        ### SERVER SENT EVENT
        get 'sse/updateEvt',        to: 'sse_events#update_events'
        get 'sse/deleteEvent',      to: 'sse_events#delete_event'
        # get 'sse/redisDeleteEvent', to: 'sse_events#redis_delete_event' 
      end
    end

    mount ActionCable.server => '/cable'
    

    mount Sidekiq::Web => '/sidekiq'
    get '*path', to: 'application#routing_error'
    
    
  end

