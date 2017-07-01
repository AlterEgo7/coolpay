class Payment
  attr_reader :status, :recipient_id, :id, :currency, :amount

  def initialize(status, recipient_id, id, currency, amount)
    @status = status
    @recipient_id = recipient_id
    @id = id
    @currency = currency
    @amount = amount
  end

  def ==(other)
    (other.class == self.class) && (id == other.id)
  end
end