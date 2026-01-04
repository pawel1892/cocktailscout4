Rails.application.routes.draw do

  root :to => 'index#index'

  resources :user_profiles, :only => ['show']
  resource :user_profile, :only => ['edit', 'update']

  resources :private_messages

  scope(:path_names => { :new => "neu", :edit => "bearbeiten" }) do
    resources :recipes, :path => "rezepte", :only => ['index', 'show', 'update', 'new', 'create', 'edit'] do
      patch 'tags/bearbeiten', action: 'update_tags', as: :tags_edit
      resources :recipe_images, :path => "bilder", :only => [:create, :new]
      resources :recipe_comments, :path => "kommentare"
    end
  end

  get '/toplisten' => 'recipes#top_lists', as: :top_lists
  get '/rezept-kategorien' => 'recipes#tag_cloud', as: :tag_cloud
  get '/tag/:tag_slug' => 'recipes#tag', as: :tags_recipes

  resources :recipe_images, :path => "cocktailgalerie", :only => [:index, :destroy] do
    patch :approve
  end

  resources :ingredients

  post '/rate' => 'rater#create', :as => 'rate'

  post '/favorite_recipe_toggle' => 'user_recipes#toggle', :as => 'favorite_recipe_toggle'

  get '/zutatensuche' => 'ingredient_search#index', :as => 'ingredient_search'
  post '/zutatensuche' => 'ingredient_search#create', :as => 'ingredient_search_create'
  post '/mybar_save' => 'ingredient_search#load', :as => 'ingredient_search_load'

  #match '/kommentare/rezept/:url_name(/:page)', :controller => 'recipe_comments', :action => 'list', :as => :list_recipe_comments

  resources :users, :only => ['index'] do
    collection do
      get '/whoiswho', action: 'whoiswho'
    end
  end
  resources :blog_entries

  get 'cocktailforum' => 'forum_topics#index', :as => :forum_topics
  get 'cocktailforum/kategorie/:id' => 'forum_topics#show', :as => :forum_topic

  get 'cocktailforum/thema/:id' => 'forum_threads#show', :as => :forum_thread
  get 'cocktailforum/kategorie/:topic_id/themen/neu' => 'forum_threads#new', :as => :new_forum_threads
  post 'cocktailforum/kategorie/:topic_id/themen' => 'forum_threads#create', :as => :forum_threads

  get 'cocktailforum/thema/:thread_id/beitrag/neu' => 'forum_posts#new', :as => :new_forum_posts
  post 'cocktailforum/thema/:thread_id/beitrag' => 'forum_posts#create', :as => :forum_posts
  get 'cocktailforum/beitrag/:id/bearbeiten' => 'forum_posts#edit', :as => :edit_forum_post
  patch 'cocktailforum/beitrag/:id' => 'forum_posts#update', :as => :forum_post
  delete 'cocktailforum/beitrag/:id' => 'forum_posts#destroy'
  get 'cocktailforum/beitrag/:id/melden' => 'forum_posts#report', :as => :report_forum_post
  post 'cocktailforen/suche' => 'forum_search#search', :as => :search_forum

  get 'community' => 'community#index', :as => :community

  get 'cocktailwissen/hausbar' => 'knowledge_base#hausbar', :as => :knowledge_base_hausbar

  get 'impressum' => 'static#imprint', :as => :static_imprint
  get 'datenschutz' => 'static#privacy', :as => :static_privacy
  get 'react' => 'static#react', :as => :react

  devise_for :users, :path => '', :path_names => {:sign_in => 'login', :sign_out => 'logout', :sign_up => 'registrieren'}

  namespace :api do
    resources :shoutbox_entries
  end

  get '/error_test' => 'static#error_test'
end
