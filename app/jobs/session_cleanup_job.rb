class SessionCleanupJob < ApplicationJob
  queue_as :default

  def perform
    Session.where("updated_at < ?", 30.days.ago).delete_all
  end
end
