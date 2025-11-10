Rails.application.routes.draw do
  resource :session
  resources :users, only: [:show]
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Mount the mission_control-jobs engine
  mount MissionControl::Jobs::Engine, at: "/jobs"

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", :as => :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  # root "posts#index"

  root to: "home#index"
  get "/my_activities", to: "home#index"
  get "/group_activities", to: "home#group_activities", as: :group_activities
  get "/history", to: "home#history", as: :activity_history

  resources :activities, only: [:show, :destroy] do
    resources :tasks, only: [:show] do
      member do
        post :run
      end
    end
  end
  get "/activities/new/:type", to: "activities#new", as: "new_activity_with_type"
  post "/activities", to: "activities#create"

  resources :manifest_registries, only: [:index, :show, :create, :destroy] do
    member do
      post :run
    end
  end
end
