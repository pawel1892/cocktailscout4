Rails.application.routes.draw do
  resource :session
  resource :registration, only: %i[new create]
  resources :passwords, param: :token
  resources :recipes, path: "rezepte", only: [ :index, :show ] do
    member do
      post :comment, to: "recipe_comments#create"
    end
  end
  resources :recipe_images, path: "cocktailgalerie", only: [ :index ]

  post "rate", to: "ratings#create"
  delete "rate", to: "ratings#destroy"

  # Forum routes (legacy URLs)
  get "cocktailforum", to: "forum_topics#index", as: :forum_topics
  get "cocktailforum/kategorie/:id", to: "forum_threads#index", as: :forum_topic
  get "cocktailforum/thema/:id", to: "forum_threads#show", as: :forum_thread

  get "design-system", to: "design_system#index"
  root "home#index"
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  # root "posts#index"
end
