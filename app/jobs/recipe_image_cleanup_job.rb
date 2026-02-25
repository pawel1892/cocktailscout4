class RecipeImageCleanupJob < ApplicationJob
  queue_as :default

  def perform
    RecipeImage.soft_deleted.where("deleted_at < ?", 1.month.ago).find_each(&:destroy!)
  end
end
