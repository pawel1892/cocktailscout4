Rails.application.routes.draw do
  resource :session
  resource :registration, only: %i[new create]
  resources :confirmations, only: %i[new create edit], param: :token
  resources :passwords, param: :token
  get "email_aendern", to: "email_changes#new", as: :new_email_change
  resource :email_change, only: [ :create, :edit ], path: "email_aendern"

  get "passwort_aendern", to: "password_changes#new", as: :new_password_change
  resource :password_change, only: [ :create ], path: "passwort_aendern"

  resources :reports, only: [ :create ]

  namespace :admin do
    resources :reports, only: [ :index, :update ] do
      collection do
        get :count
      end
    end
  end

  resources :user_profiles, only: [ :show, :update ]
  resources :users, path: "benutzer", only: [ :index ]
  resources :recipes, path: "rezepte", param: :slug do
    member do
      post :comment, to: "recipe_comments#create"
      patch :publish
    end
    resources :recipe_ingredients, only: [ :index ], path: "zutaten"
  end
  resources :recipe_categories, path: "rezept-kategorien", only: [ :index ]
  resources :top_lists, path: "toplisten", only: [ :index ]
  resources :recipe_comments, only: [ :edit, :update, :destroy ]
  resources :recipe_images, path: "cocktailgalerie", only: [ :index ]

  get "tag/:tag", to: "recipes#index", as: :tag

  post "rate", to: "ratings#create"
  delete "rate", to: "ratings#destroy"

  post "favorite", to: "favorites#create"
  delete "favorite", to: "favorites#destroy"

  # My Bar (Ingredient Collections UI)
  get "meine-bar", to: "my_bar#index", as: :my_bar

  # Ingredients API (for search)
  resources :ingredients, only: [ :index ]

  # Units API (for recipe form)
  resources :units, only: [ :index ]

  # Ingredient Collections API
  resources :ingredient_collections, only: [ :index, :show, :create, :update, :destroy ] do
    member do
      get :edit  # HTML page for managing ingredients
    end
    resources :ingredients, only: [ :create, :destroy ], controller: "ingredient_collections/ingredients" do
      collection do
        put "", action: :update  # PUT /ingredient_collections/:id/ingredients (replace all)
      end
    end
  end

  # Forum routes (legacy URLs)
  get "cocktailforum", to: "forum_topics#index", as: :forum_topics
  get "community", to: "community#index", as: :community
  get "cocktailforum/kategorie/:id", to: "forum_threads#index", as: :forum_topic

  get "cocktailforum/kategorie/:topic_id/themen/neu", to: "forum_threads#new", as: :new_forum_thread
  post "cocktailforum/kategorie/:topic_id/themen", to: "forum_threads#create", as: :create_forum_thread

  get "cocktailforum/thema/:id", to: "forum_threads#show", as: :forum_thread
  post "cocktailforum/thema/:thread_id/sperren", to: "forum_thread_locks#create", as: :lock_forum_thread
  delete "cocktailforum/thema/:thread_id/sperren", to: "forum_thread_locks#destroy", as: :unlock_forum_thread
  post "cocktailforum/thema/:thread_id/anpinnen", to: "forum_thread_pins#create", as: :pin_forum_thread
  delete "cocktailforum/thema/:thread_id/anpinnen", to: "forum_thread_pins#destroy", as: :unpin_forum_thread
  get "cocktailforum/suche", to: "forum_search#index", as: :forum_search

  # Forum Posts
  get "cocktailforum/thema/:thread_id/beitrag/neu", to: "forum_posts#new", as: :new_forum_post
  post "cocktailforum/thema/:thread_id/beitrag", to: "forum_posts#create", as: :forum_posts

  get "cocktailforum/beitrag/:public_id", to: "forum_posts#show", as: :show_forum_post
  get "cocktailforum/beitrag/:id/bearbeiten", to: "forum_posts#edit", as: :edit_forum_post
  patch "cocktailforum/beitrag/:id", to: "forum_posts#update", as: :forum_post
  delete "cocktailforum/beitrag/:id", to: "forum_posts#destroy"

  # Private Messages
  resources :private_messages, path: "nachrichten", only: [ :index, :show, :new, :create, :destroy ] do
    collection do
      get :sent
      get :unread_count
    end
  end

  get "design-system", to: "design_system#index"

  get "impressum", to: "pages#impressum"
  get "datenschutz", to: "pages#datenschutz"

  root "home#index"
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  # root "posts#index"
end
