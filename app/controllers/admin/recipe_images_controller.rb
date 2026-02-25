module Admin
  class RecipeImagesController < BaseController
    before_action :require_image_moderator!
    before_action :set_recipe_image, only: [ :show, :approve, :reject, :destroy, :restore, :rotate_left, :rotate_right ]

    def index
      @recipe_images = RecipeImage.includes(:recipe, :user, :moderated_by)
                                   .then { |q| filter_by_state(q) }
                                   .then { |q| filter_by_recipe_name(q) }
                                   .recent
      @pagy, @recipe_images = pagy(@recipe_images, limit: 50)
    end

    def show; end

    def approve
      @recipe_image.approve!(Current.user)
      send_approval_message
      redirect_to admin_recipe_images_path, notice: "Bild wurde genehmigt."
    rescue ActiveRecord::RecordInvalid => e
      redirect_to admin_recipe_image_path(@recipe_image), alert: "Fehler: #{e.message}"
    end

    def reject
      reason = params[:moderation_reason].presence
      @recipe_image.reject!(Current.user, reason)
      send_rejection_message(reason)
      redirect_to admin_recipe_images_path, notice: "Bild wurde abgelehnt."
    rescue ActiveRecord::RecordInvalid => e
      redirect_to admin_recipe_image_path(@recipe_image), alert: "Fehler: #{e.message}"
    end

    def destroy
      if @recipe_image.pending?
        redirect_to admin_recipe_image_path(@recipe_image), alert: "Bild muss zuerst genehmigt oder abgelehnt werden, damit der Uploader eine Rückmeldung erhält."
        return
      end
      @recipe_image.soft_delete!
      redirect_to admin_recipe_image_path(@recipe_image), notice: "Bild wurde gelöscht."
    end

    def restore
      @recipe_image.restore!
      redirect_to admin_recipe_image_path(@recipe_image), notice: "Bild wurde wiederhergestellt."
    end

    def rotate_left
      @recipe_image.rotate_image!(-90)
      redirect_to admin_recipe_image_path(@recipe_image), notice: "Bild wurde nach links gedreht."
    rescue => e
      redirect_to admin_recipe_image_path(@recipe_image), alert: "Fehler: #{e.message}"
    end

    def rotate_right
      @recipe_image.rotate_image!(90)
      redirect_to admin_recipe_image_path(@recipe_image), notice: "Bild wurde nach rechts gedreht."
    rescue => e
      redirect_to admin_recipe_image_path(@recipe_image), alert: "Fehler: #{e.message}"
    end

    def count
      render json: { count: RecipeImage.pending.count }
    end

    private

    def require_image_moderator!
      unless Current.user&.can_moderate_image?
        redirect_to root_path, alert: "Zugriff verweigert."
      end
    end

    def set_recipe_image
      @recipe_image = RecipeImage.includes(:recipe, :user, :moderated_by).find(params[:id])
    end

    def filter_by_recipe_name(query)
      return query if params[:q].blank?
      query.joins(:recipe).where("recipes.title LIKE ?", "%#{params[:q]}%")
    end

    def filter_by_state(query)
      case params[:state]
      when "pending"  then query.pending.not_soft_deleted
      when "approved" then query.approved.not_soft_deleted
      when "rejected" then query.rejected.not_soft_deleted
      when "deleted"  then query.soft_deleted
      else query
      end
    end

    def send_approval_message
      recipe = @recipe_image.recipe
      recipe_link = recipe_url(recipe.slug)
      PrivateMessage.create!(
        sender:   Current.user,
        receiver: @recipe_image.user,
        subject:  "Dein Bild wurde genehmigt! 🎉",
        body:     "Herzlichen Glückwunsch!\n\nDein hochgeladenes Bild für das Rezept \"#{recipe.title}\" wurde von unserem Team geprüft und freigegeben. Es ist jetzt in der Cocktailgalerie sichtbar.\n\nVielen Dank, dass du dazu beiträgst, unsere Community zu bereichern!\n\nZum Rezept: #{recipe_link}"
      )
    end

    def send_rejection_message(reason)
      recipe = @recipe_image.recipe
      body = "Leider müssen wir dir mitteilen, dass dein hochgeladenes Bild für das Rezept \"#{recipe.title}\" nicht freigegeben werden konnte."
      if reason.present?
        body += "\n\nBegründung: #{reason}"
      end
      body += "\n\nBei Fragen kannst du uns jederzeit kontaktieren."
      PrivateMessage.create!(
        sender:   Current.user,
        receiver: @recipe_image.user,
        subject:  "Bild konnte nicht genehmigt werden",
        body:     body
      )
    end
  end
end
