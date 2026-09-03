# A hostname pointing at one site.
#
# Caddy issues certificates on demand, and asks this application first. A host
# only earns a certificate once it appears in this table, which keeps strangers
# from aiming their domains here and burning the Let's Encrypt rate limit.
class Domain < ApplicationRecord
  belongs_to :site

  # Hostnames are case-insensitive, and a trailing dot is legal in DNS but
  # never appears in a Host header. Both are normalised away on the way in.
  normalizes :host, with: ->(value) { value.to_s.strip.downcase.delete_suffix(".") }

  validates :host, presence: true, uniqueness: true,
                   format: { with: /\A(?=.{1,253}\z)(?:[a-z0-9](?:[a-z0-9-]{0,61}[a-z0-9])?\.)+[a-z]{2,63}\z/,
                             message: "does not look like a domain name" }

  validate :single_primary_per_site
  before_validation :claim_primary_if_first

  scope :primary, -> { where(primary: true) }

  # Marks this domain as the canonical one, demoting whichever held the role.
  def make_primary!
    transaction do
      site.domains.where.not(id: id).update_all(primary: false)
      update!(primary: true)
    end
  end

  def certified? = certified_at.present?

  private

    # A site's first domain is its canonical one. Putting the rule here rather
    # than in the controller matters: `site.domains.new` pushes the unsaved
    # record into the loaded association, so asking the association whether it
    # is empty answers "no" and the first domain never became primary.
    def claim_primary_if_first
      return if primary?
      return if site_id.blank?

      self.primary = Domain.where(site_id: site_id).where.not(id: id).none?
    end

    def single_primary_per_site
      return unless primary?
      return if site.blank?

      clash = site.domains.primary.where.not(id: id).exists?
      errors.add(:primary, "is already set on another domain of this site") if clash
    end
end
