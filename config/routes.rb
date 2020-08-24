  Rails.application.routes.draw do
  post 'user_token' => 'user_token#create'
    namespace :api do
      namespace :v1 do
        resources :users, only: [:index, :show]
        resources :events, only: [:index, :create, :update, :destroy, :show]
        post '/getUserToken', to: 'user_token#create'
        get '/profile', to: 'users#profile'
        post '/createUser', to: 'users#create_user'
        get '/mailconfirmation', to: 'users#confirmed_email'
        post '/findCreateFbUser', to: 'users#find_create_with_fb'
        post '/pushDemand', to:'events#receive_demand'
        get 'itinaries', to: 'itinaries#index'
        get 'confirmDemand', to: 'events#confirm_demand'
      end
    end
    root to: 'events#index'

    mount Sidekiq::Web => '/sidekiq'
    
    get '*path', to: 'application#routing_error'
  end

