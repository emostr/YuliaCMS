module PublicHelper
  def page_title
    [ @page&.seo_title.presence || @page&.title, @site&.name ].compact.uniq.join(" — ")
  end

  def page_description = @page&.seo_description.to_s

  def canonical_url
    base = @site.primary_domain ? "https://#{@site.primary_domain.host}" : request.base_url
    "#{base}#{@page&.path}"
  end

  # htmx earns its place on a page only if something there speaks it. Built-in
  # form blocks do; so does any custom block whose template mentions an hx-
  # attribute.
  def needs_htmx?(blocks)
    return false if blocks.blank?

    types = Array(blocks).filter_map { |block| block["type"].to_s }.uniq
    return true if types.include?("form")

    @site.block_types.enabled.where(key: types).any? { |bt| bt.template.include?("hx-") }
  end

  # Renders one block. Kept here so the view stays a list of blocks rather than
  # a nest of conditionals.
  def render_block(block)
    @renderer.render(block)
  end
end
