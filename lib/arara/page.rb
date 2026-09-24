module Arara
  Pagination = Struct.new(:page, :size, :total_elements, :total_pages, keyword_init: true)

  class Page
    include Enumerable

    attr_reader :data, :pagination, :raw

    def self.from_data(response)
      body = response.is_a?(Hash) ? response : {}
      meta = body["pagination"].is_a?(Hash) ? body["pagination"] : {}
      new(
        data: Array(body["data"]),
        pagination: Pagination.new(
          page: meta["page"], size: meta["size"],
          total_elements: meta["totalElements"], total_pages: meta["totalPages"]
        ),
        raw: response
      )
    end

    def self.from_content(response, page:, size:)
      body = response.is_a?(Hash) ? response : {}
      new(
        data: Array(body["content"]),
        pagination: Pagination.new(
          page: page, size: size,
          total_elements: body["totalElements"], total_pages: body["totalPages"]
        ),
        raw: response
      )
    end

    def initialize(data:, pagination:, raw: nil)
      @data = data
      @pagination = pagination
      @raw = raw
    end

    def each(&block)
      @data.each(&block)
    end

    def next_page?
      return false if @pagination.page.nil? || @pagination.total_pages.nil?

      @pagination.page + 1 < @pagination.total_pages
    end
  end
end
