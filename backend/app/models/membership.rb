# Grants a user access to one site.
class Membership < ApplicationRecord
  ROLES = %w[owner editor].freeze

  belongs_to :user
  belongs_to :site

  validates :role, inclusion: { in: ROLES }
  validates :user_id, uniqueness: { scope: :site_id }
end
