class Payment
  attr_reader :status, :recipient_id, :id, :currency, :amount

  def initialize(options)
    validate!(options)

    @status = options['status']
    @recipient_id = options['recipient_id']
    @id = options['id']
    @currency = options['currency']
    @amount = options['amount']
  end

  def ==(other)
    (other.class == self.class) && (id == other.id)
  end


  def validate!(options)
    raise ArgumentError 'status cannot be empty' if options['status'].to_s.empty?
    raise ArgumentError 'recipient_id cannot be empty' if options['recipient_id'].to_s.empty?
    raise ArgumentError 'id cannot be empty' if options['id'].to_s.empty?
    raise ArgumentError 'currency cannot be empty' if options['currency'].to_s.empty?
    raise ArgumentError 'amount must be greater than 0' unless options['amount'].to_f > 0.0
  end

end