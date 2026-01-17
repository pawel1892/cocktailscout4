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

  get "tag/:tag", to: "recipes#index", as: :tag

  post "rate", to: "ratings#create"
  delete "rate", to: "ratings#destroy"

  # Ingredient Collections API
  resources :ingredient_collections, only: [ :index, :show, :create, :update, :destroy ] do
    resources :ingredients, only: [ :create, :destroy ], controller: "ingredient_collections/ingredients" do
      collection do
        put "", action: :update  # PUT /ingredient_collections/:id/ingredients (replace all)
      end
    end
  end

  # Forum routes (legacy URLs)
  get "cocktailforum", to: "forum_topics#index", as: :forum_topics
  get "cocktailforum/kategorie/:id", to: "forum_threads#index", as: :forum_topic

  get "cocktailforum/kategorie/:topic_id/themen/neu", to: "forum_threads#new", as: :new_forum_thread
  post "cocktailforum/kategorie/:topic_id/themen", to: "forum_threads#create", as: :create_forum_thread

  get "cocktailforum/thema/:id", to: "forum_threads#show", as: :forum_thread
  get "cocktailforum/suche", to: "forum_search#index", as: :forum_search

  # Forum Posts
  get "cocktailforum/thema/:thread_id/beitrag/neu", to: "forum_posts#new", as: :new_forum_post
  post "cocktailforum/thema/:thread_id/beitrag", to: "forum_posts#create", as: :forum_posts

  get "cocktailforum/beitrag/:id/bearbeiten", to: "forum_posts#edit", as: :edit_forum_post
  patch "cocktailforum/beitrag/:id", to: "forum_posts#update", as: :forum_post
  delete "cocktailforum/beitrag/:id", to: "forum_posts#destroy"

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
