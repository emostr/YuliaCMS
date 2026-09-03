# A page of a site.
#
# Content is a JSON document - an ordered array of blocks - rather than a table
# of block rows. Reordering in the visual editor is then a single column write,
# and the draft/published split costs one more column instead of a parallel set
# of rows that has to be kept in step.
class Page < ApplicationRecord
  STATUSES = %w[draft published].freeze

  belongs_to :site
  belongs_to :parent, class_name: "Page", optional: true

  has_many :children, class_name: "Page", foreign_key: :parent_id, dependent: :nullify
  has_many :revisions, -> { order(created_at: :desc) },
           class_name: "PageRevision", dependent: :destroy
  has_many :form_submissions, dependent: :nullify

  normalizes :slug, with: ->(value) { value.to_s.strip.downcase }

  validates :title, presence: true
  validates :status, inclusion: { in: STATUSES }
  validates :slug, presence: true,
                   format: { with: /\A[a-z0-9](?:[a-z0-9-]*[a-z0-9])?\z/,
                             message: "may contain only lowercase letters, digits and hyphens" },
                   unless: :home?
  validates :path, presence: true, uniqueness: { scope: :site_id }
  validate :one_home_page_per_site

  before_validation :assign_path

  scope :published, -> { where(status: "published") }
  scope :ordered, -> { order(:position, :id) }

  def published? = status == "published"

  # What a visitor sees. A page being edited keeps serving its last published
  # version, so an unfinished draft never reaches the public site.
  def live_content = published_content || []

  def draft_blocks = draft_content || []

  # Snapshots the current draft before overwriting it, so an accidental change
  # is always one click from being undone.
  def save_draft!(blocks, user: nil)
    transaction do
      revisions.create!(content: draft_blocks, user: user, created_at: Time.current) if draft_blocks.any?
      update!(draft_content: blocks)
      prune_revisions!
    end
  end

  def publish!(user: nil)
    transaction do
      revisions.create!(content: draft_blocks, user: user, label: "published", created_at: Time.current)
      update!(status: "published", published_content: draft_blocks, published_at: Time.current)
      prune_revisions!
    end
  end

  def unpublish! = update!(status: "draft")

  # Puts a published page back into the editor as it went live. Useful when a
  # draft has wandered somewhere the author would rather abandon.
  def restore_published_into_draft!
    update!(draft_content: live_content)
  end

  MAX_REVISIONS = 50

  private

    # History is a safety net, not an archive: keeping every keystroke forever
    # would grow the table without bound on a server the user cannot see.
    def prune_revisions!
      surplus = revisions.offset(MAX_REVISIONS).pluck(:id)
      PageRevision.where(id: surplus).delete_all if surplus.any?
    end

    def assign_path
      self.path = home? ? "/" : "/#{slug}"
    end

    def one_home_page_per_site
      return unless home?
      return if site.blank?

      clash = site.pages.where(home: true).where.not(id: id).exists?
      errors.add(:home, "is already set on another page of this site") if clash
    end
end
