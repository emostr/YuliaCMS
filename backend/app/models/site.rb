# One website. A single Yulia installation hosts many of them, which is why the
# user never has to come back to the server to launch a second site.
class Site < ApplicationRecord
  THEMES = %w[light dark].freeze

  # The NightingaleUI accents, shared with the admin panel.
  ACCENTS = %w[teal azure magenta amber violet lime].freeze

  has_many :domains, dependent: :destroy
  has_many :pages, dependent: :destroy
  has_many :block_types, dependent: :destroy
  has_many :media_items, dependent: :destroy
  has_many :form_submissions, dependent: :destroy
  has_many :memberships, dependent: :destroy
  has_many :users, through: :memberships

  normalizes :slug, with: ->(value) { value.to_s.strip.downcase }

  validates :name, presence: true
  validates :slug, presence: true, uniqueness: true,
                   format: { with: /\A[a-z0-9](?:[a-z0-9-]*[a-z0-9])?\z/,
                             message: "may contain only lowercase letters, digits and hyphens" }
  validates :theme, inclusion: { in: THEMES }
  validates :accent, inclusion: { in: ACCENTS }
  validates :locale, presence: true
  validates :timezone, presence: true

  scope :published, -> { where(published: true) }

  def home_page = pages.find_by(home: true)

  def primary_domain = domains.find_by(primary: true) || domains.first

  # Where the live site can be reached. Falls back to the slug-based address
  # served by the admin host, so a site is previewable before it has a domain.
  def public_url
    domain = primary_domain
    domain ? "https://#{domain.host}" : "#{Yulia.admin_url}/preview/#{slug}"
  end

  def publish!
    update!(published: true, published_at: Time.current)
  end

  def unpublish! = update!(published: false)
end
