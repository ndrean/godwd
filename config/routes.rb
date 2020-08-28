  Rails.application.routes.draw do
  #post 'user_token' => 'user_token#create'
    namespace :api do
      namespace :v1 do
        
        #knock
        post '/getUserToken',     to: 'user_token#create'
        get '/fbParams',          to: 'users#fb_params'
        resources :users, only: [:index, :show]
        get '/profile',           to: 'users#profile'
        post '/findUser',         to: 'users#find_user'
        post '/createUser',       to: 'users#create_user'
        get '/mailconfirmation',  to: 'users#confirmed_email'
        post '/findCreateFbUser', to: 'users#find_create_with_fb'

        resources :events, only: [:index, :create, :update, :destroy, :show]
        post '/pushDemand',       to:'events#receive_demand'
        get 'confirmDemand',      to: 'events#confirm_demand'
        
        get 'itinaries',          to: 'itinaries#index'
      end
    end

    root to: 'events#index'

    mount Sidekiq::Web => '/sidekiq'
    
    get '*path', to: 'application#routing_error'
  end

