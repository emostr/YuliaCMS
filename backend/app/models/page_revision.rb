# A snapshot of a page's draft, taken before it was overwritten or published.
class PageRevision < ApplicationRecord
  belongs_to :page
  belongs_to :user, optional: true

  scope :recent, -> { order(created_at: :desc) }
end
