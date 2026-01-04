class BlogEntriesController < ApplicationController
  load_and_authorize_resource

  def index
    @blog_entries = BlogEntry.all.page(params[:page]).per(7).order("created_at DESC")
  end

  def show
    @blog_entry = BlogEntry.find(params[:id])
  end

end