module PaginationQuery
  extend ActiveSupport::Concern

  included do
    OFFSET_DEFAULT = 0
    LIMIT_DEFAULT = 20

    attr_accessor :offset, :limit

    validates :offset,
      numericality: {
        only_integer: true,
        greater_than_or_equal_to: 0,
        less_than_or_equal_to: 1000
      },
      allow_nil: true
    validates :limit,
      numericality: {
        only_integer: true,
        greater_than_or_equal_to: 0,
        less_than_or_equal_to: 100
      },
      allow_nil: true

    def offset
      @offset || OFFSET_DEFAULT
    end

    def limit
      @limit || LIMIT_DEFAULT
    end
  end
end
