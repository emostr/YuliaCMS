module Api
  class MediaItemsController < BaseController
    def index
      items = current_site.media_items.includes(file_attachment: :blob).order(created_at: :desc)
      render json: { media: items.map { |item| serialize(item) } }
    end

    def create
      item = current_site.media_items.new(
        user: current_user,
        title: params[:title].to_s,
        alt: params[:alt].to_s
      )
      item.file.attach(params.require(:file))
      item.save!

      render json: { media: serialize(item) }, status: :created
    end

    def destroy
      item = MediaItem.where(site: accessible_sites).find(params[:id])
      item.destroy!
      head :no_content
    end

    private

      def serialize(item)
        {
          id: item.id, title: item.title, alt: item.alt,
          url: item.file.attached? ? url_for(item.file) : nil,
          content_type: item.file.attached? ? item.file.content_type : nil,
          byte_size: item.file.attached? ? item.file.byte_size : 0,
          created_at: item.created_at
        }
      end
  end
end
