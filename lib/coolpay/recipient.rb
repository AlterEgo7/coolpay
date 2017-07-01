module Coolpay
  class Recipient
    attr_reader :name, :id

    def initialize(name, id)
      name.to_s.empty? ? raise(ArgumentError, 'name is mandatory') : @name = name
      id.to_s.empty? ? raise(ArgumentError, 'ID is mandatory') : @id = id
    end

    def ==(other)
      # Suppose the backend takes care for uniqueness of ids
      (other.class == self.class) && (id == other.id)
    end


  end
end