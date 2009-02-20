module ActsAsMoney
  module Forex 
    class Service
      
      def exchange(money, new_currency)
        raise NoConversionAvailableError unless rates[new_currency]
        return money if money.currency == new_currency
        
        new_amount = rates[new_currency] * money.amount / rates[money.currency]
        
        Money.new new_amount.ceil, new_currency
      end
      
    end
  end
end