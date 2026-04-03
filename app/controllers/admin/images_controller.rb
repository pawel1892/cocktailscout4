module Admin
  class ImagesController < BaseController
    before_action :require_image_moderator!

    def index
      @tab = params[:tab] || "forum"

      case @tab
      when "forum"
        scope = ForumImage.includes(:user, image_attachment: :blob).order(created_at: :desc)
        scope = scope.marked_as_orphaned if params[:filter] == "orphan"
        @pagy, @images = pagy(scope, limit: 50)
      when "avatar"
        scope = ActiveStorage::Attachment
          .where(record_type: "User", name: "avatar")
          .includes(:blob, :record)
          .order(created_at: :desc)
        @pagy, @images = pagy(scope, limit: 50)
      when "recipe"
        redirect_to admin_recipe_images_path
      end
    end

    def destroy
      @forum_image = ForumImage.find(params[:id])
      @forum_image.image.purge_later
      @forum_image.destroy
      redirect_to admin_images_path(tab: "forum", filter: params[:filter]), notice: "Bild gelöscht."
    end

    def restore
      @forum_image = ForumImage.find(params[:id])
      @forum_image.restore!
      redirect_to admin_images_path(tab: "forum", filter: "orphan"), notice: "Bild wiederhergestellt."
    end

    def destroy_avatar
      user = User.find(params[:id])
      user.avatar.purge_later
      redirect_to admin_images_path(tab: "avatar"), notice: "Avatar von #{user.username} gelöscht."
    end

    private

    def require_image_moderator!
      unless Current.user&.can_moderate_image?
        redirect_to root_path, alert: "Zugriff verweigert."
      end
    end
  end
end
