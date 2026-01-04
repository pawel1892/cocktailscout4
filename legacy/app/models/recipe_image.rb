class RecipeImage < ActiveRecord::Base
  has_attached_file :image, :styles => { :big => "1200x1200>", :medium => "500x500>", :thumb => "100x100>" },
                    :url  => "/user_img/recipe/:id/:style/:basename.:extension",
                    :path => ":rails_root/public/user_img/recipe/:id/:style/:basename.:extension"

  validates_attachment_content_type :image, :content_type => ["image/jpg", "image/jpeg", "image/png"]

  belongs_to :recipe
  belongs_to :user

  scope :approved, -> {where is_approved: true}
  scope :not_approved, -> {where is_approved: false}
  scope :to_approve, -> {where is_approved: nil}

  def approve!(user, approve_state)
    self.approved_by = user.id
    self.is_approved = approve_state
    save
  end

end
