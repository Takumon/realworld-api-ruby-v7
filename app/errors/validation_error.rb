class ValidationError < StandardError
  attr_reader :errors, :status

  def initialize(errors, status = :bad_request)
    if errors.is_a?(Array)
      @errors = errors
    else
      @errors = [] if @errors.nil?
      @errors.push(errors)
    end

    @status = status

    super(@errors.join(", "))
  end
end
