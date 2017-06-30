module Coolpay
  class Recipient
    attr_reader :name, :id

    def initialize(name, id)
      name.to_s.empty? ? raise(ArgumentError, 'name is mandatory') : @name = name
      id.to_s.empty? ? raise(ArgumentError, 'ID is mandatory') : @id = id
    end
  end
end