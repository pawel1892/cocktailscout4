class ForumImagesController < ApplicationController
  def create
    forum_image = ForumImage.new(user: Current.user)
    forum_image.image.attach(params[:image])

    if forum_image.save
      render json: { success: true, url: rails_blob_path(forum_image.image, only_path: true) }
    else
      render json: { success: false, errors: forum_image.errors.full_messages }, status: :unprocessable_entity
    end
  end
end
