class MyBarController < ApplicationController
  allow_unauthenticated_access only: [ :index ]

  def index
    add_breadcrumb "Meine Bar", my_bar_path
  end
end
