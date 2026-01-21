class Report < ApplicationRecord
  belongs_to :reporter, class_name: "User"
  belongs_to :resolved_by, class_name: "User", optional: true
  belongs_to :reportable, polymorphic: true

    enum :reason, { spam: 0, inappropriate: 1, harassment: 2, other: 3 }
    enum :status, { pending: 0, resolved: 1, dismissed: 2 }

    validates :reason, presence: true
    validates :description, presence: true, if: :other?

    scope :unresolved, -> { where(status: :pending) }
end
