class Visit < ActiveRecord::Base

  belongs_to :visitable, :polymorphic => true

  def self.track(visitable_obj, user = nil)
    user_id = user ? user.id : nil
    visit = Visit.find_or_create_by!(visitable_id: visitable_obj.id,visitable_type: visitable_obj.class.name,user_id: user_id)
    visit.total_visits += 1
    visit.last_visit_time = Time.now
    visit.save
  end

end
