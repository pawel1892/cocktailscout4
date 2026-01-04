module Visitable
  def visits_count
    self.visits.sum(:total_visits)
  end

  def visits_count_by(user)
    self.visits.where(:user_id => user.id).sum(:total_visits)
  end

  def last_visit_time
    last_visit = self.visits.order('last_visit_time DESC').first
    if last_visit
      last_visit.last_visit_time
    else
      nil
    end
  end

  def last_visit_time_by(user)
    last_visit = self.visits.where(:user_id => user.id).order('last_visit_time DESC').first
    if last_visit
      last_visit.last_visit_time
    else
      nil
    end
  end

end