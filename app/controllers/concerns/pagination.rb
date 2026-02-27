module Pagination
  extend ActiveSupport::Concern

  DEFAULT_PAGE_SIZE = 100
  MAX_PAGE_SIZE = 500

  def render_paginated(relation, **options)
    records = paginate(relation).to_a
    if records.size >= page_size
      options = options.merge(links: { next: next_page_url })
    end
    render_models(records, **options)
  end

  private

  def page_number
    @page_number ||= [(params.dig(:page, :number) || 1).to_i, 1].max
  end

  def page_size
    @page_size ||= (params.dig(:page, :size) || DEFAULT_PAGE_SIZE).to_i.clamp(1, MAX_PAGE_SIZE)
  end

  def paginate(relation)
    relation.offset((page_number - 1) * page_size).limit(page_size)
  end

  def next_page_url
    query = request.query_parameters.deep_dup
    query["page"] = { "number" => page_number + 1, "size" => page_size }
    "#{request.base_url}#{request.path}?#{query.to_query}"
  end
end
