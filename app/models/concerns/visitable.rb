module Visitable
  extend ActiveSupport::Concern

  included do
    has_many :visits, as: :visitable, dependent: :destroy
  end

  def track_visit(user = nil)
    user_id = user&.id

    visit = visits.find_or_create_by!(user_id: user_id)
    visit.with_lock do
      visit.increment!(:count, touch: false)
      visit.update_columns(last_visited_at: Time.current, updated_at: Time.current)
    end
  end

  def total_visits
    visits.sum(:count)
  end

  def visits_by(user)
    visits.find_by(user: user)&.count || 0
  end

  def last_visited_at
    visits.maximum(:last_visited_at)
  end

  def last_visited_at_by(user)
    visits.find_by(user: user)&.last_visited_at
  end
end
