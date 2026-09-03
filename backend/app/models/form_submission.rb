# Something a visitor sent through a form block.
class FormSubmission < ApplicationRecord
  belongs_to :site
  belongs_to :page, optional: true

  scope :unread, -> { where(read: false) }
  scope :recent, -> { order(created_at: :desc) }

  # Submissions are shown back to the site owner in the admin panel, so the
  # values are stored as text and never interpreted as anything else.
  def fields = (data || {}).transform_values(&:to_s)
end
