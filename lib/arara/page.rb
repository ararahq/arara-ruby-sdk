module Arara
  Pagination = Struct.new(:page, :size, :total_elements, :total_pages, keyword_init: true)

  class Page
    include Enumerable

    attr_reader :data, :pagination, :raw

    def self.from_data(response)
      body = require_list(response, "data")
      meta = body["pagination"].is_a?(Hash) ? body["pagination"] : {}
      new(
        data: body["data"],
        pagination: Pagination.new(
          page: meta["page"], size: meta["size"],
          total_elements: meta["totalElements"], total_pages: meta["totalPages"]
        ),
        raw: response
      )
    end

    def self.from_content(response, page:, size:)
      body = require_list(response, "content")
      new(
        data: body["content"],
        pagination: Pagination.new(
          page: page, size: size,
          total_elements: body["totalElements"], total_pages: body["totalPages"]
        ),
        raw: response
      )
    end

    def self.require_list(response, field)
      return response if response.is_a?(Hash) && response[field].is_a?(Array)

      raise Arara::Error.new("Unexpected paginated response from Arara API: missing \"#{field}\" list")
    end
    private_class_method :require_list

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
