module Yulia
  # Turns a title a person typed into something that can live in a URL.
  #
  # Rails' own `parameterize` drops every character it cannot transliterate, and
  # it has no transliteration rules for Cyrillic. A site called "Кофейня «Пар»"
  # therefore produced an empty slug and could not be created at all - which,
  # for the people Yulia is built for, is every site.
  module Slug
    RESERVED = %w[admin api preview assets yulia _yulia up].freeze

    class << self
      # Always returns something usable. A title made entirely of characters
      # that do not survive the trip still yields a slug, because refusing to
      # create the page would be worse than an imperfect address.
      def from(text, fallback: "page")
        candidate = I18n.transliterate(text.to_s, locale: :ru).parameterize

        candidate = fallback if candidate.blank?
        candidate = "#{candidate}-page" if RESERVED.include?(candidate)
        candidate.first(80)
      end

      # Appends a number until the slug is free. The block says whether a
      # candidate is already taken, so the caller decides what "taken" means.
      def unique(text, fallback: "page")
        base = from(text, fallback: fallback)
        return base unless yield(base)

        suffix = 2
        suffix += 1 while yield("#{base}-#{suffix}")
        "#{base}-#{suffix}"
      end
    end
  end
end
