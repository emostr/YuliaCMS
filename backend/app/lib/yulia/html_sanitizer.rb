module Yulia
  # Cleans markup that arrived from a person before it is served to visitors.
  #
  # Site authors are trusted with their own site, but not with the server: an
  # installation hosts several sites, and an editor on one of them must not be
  # able to run script in a visitor's browser - or in an administrator's, when
  # a page is previewed.
  module HtmlSanitizer
    # What the rich text editor can produce. Deliberately narrow: anything the
    # editor cannot create has no business arriving here.
    RICH_TEXT_TAGS = %w[
      p br strong em u s code pre blockquote
      h1 h2 h3 h4 h5 h6
      ul ol li
      a img
      table thead tbody tr th td
      span div sub sup hr
    ].freeze

    RICH_TEXT_ATTRIBUTES = %w[
      href src alt title target rel class colspan rowspan
      data-latex data-type
    ].freeze

    # Embeds are pasted from other services, so iframes are permitted - but
    # only pointing at hosts known to serve players and maps. An arbitrary
    # iframe is a phishing surface pointed at the site's own visitors.
    EMBED_TAGS = (RICH_TEXT_TAGS + %w[iframe figure figcaption video audio source]).freeze

    EMBED_ATTRIBUTES = (RICH_TEXT_ATTRIBUTES + %w[
      width height frameborder allow allowfullscreen loading
      controls poster type sandbox referrerpolicy
    ]).freeze

    ALLOWED_EMBED_HOSTS = %w[
      www.youtube.com youtube.com www.youtube-nocookie.com youtu.be
      player.vimeo.com vimeo.com
      rutube.ru
      vk.com vkvideo.ru
      yandex.ru maps.yandex.ru
      www.google.com maps.google.com
      open.spotify.com
      codepen.io
    ].freeze

    class << self
      def rich_text(html)
        sanitize(html, tags: RICH_TEXT_TAGS, attributes: RICH_TEXT_ATTRIBUTES)
      end

      def embed(html)
        cleaned = sanitize(html, tags: EMBED_TAGS, attributes: EMBED_ATTRIBUTES)
        strip_disallowed_frames(cleaned)
      end

      private

        def sanitize(html, tags:, attributes:)
          return "" if html.blank?

          ActionController::Base.helpers.sanitize(
            drop_script_content(html.to_s),
            tags: tags, attributes: attributes
          ).to_s
        end

        # The sanitiser drops a <script> element but keeps the text inside it,
        # which leaves a line of source code sitting in the middle of the page.
        # Inert, but not something a visitor should be reading, so these
        # elements are removed with their contents before sanitising.
        def drop_script_content(html)
          return html unless html.match?(/<\s*(script|style|template)\b/i)

          fragment = Nokogiri::HTML5.fragment(html)
          fragment.css("script, style, template").each(&:remove)
          fragment.to_html
        end

        # The sanitiser can keep an <iframe>, but it has no opinion on where the
        # frame points. That check happens here.
        def strip_disallowed_frames(html)
          return html if html.exclude?("<iframe")

          fragment = Nokogiri::HTML5.fragment(html)
          fragment.css("iframe").each do |frame|
            frame.remove unless allowed_frame_source?(frame["src"])
          end
          fragment.to_html
        end

        def allowed_frame_source?(src)
          return false if src.blank?

          uri = URI.parse(src)
          return false unless uri.scheme == "https"

          ALLOWED_EMBED_HOSTS.include?(uri.host.to_s.downcase)
        rescue URI::InvalidURIError
          false
        end
    end
  end
end
