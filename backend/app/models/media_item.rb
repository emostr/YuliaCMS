# An image or file in a site's media library.
class MediaItem < ApplicationRecord
  belongs_to :site
  belongs_to :user, optional: true

  has_one_attached :file

  validates :file, presence: true

  ALLOWED_TYPES = %w[
    image/png image/jpeg image/gif image/webp image/avif image/svg+xml
    application/pdf
  ].freeze

  validate :acceptable_file

  def image? = file.attached? && file.content_type.to_s.start_with?("image/")

  private

    def acceptable_file
      return unless file.attached?

      unless ALLOWED_TYPES.include?(file.content_type)
        errors.add(:file, "has a type Yulia does not accept: #{file.content_type}")
      end

      if file.byte_size > Yulia.max_upload_bytes
        errors.add(:file, "is larger than #{Yulia.max_upload_mb} MB")
      end
    end
end
