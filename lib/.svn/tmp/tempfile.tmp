require File.dirname(__FILE__) + '/forex'

module ActsAsMoney
  
  def self.included(base)
    base.extend(ClassMethods)
  end
  
  class NoConversionAvailableError < Exception
  end
  
  class Money
    attr_reader :amount, :currency
    # active_merchant compatibility
    alias_method :cents, :amount
    
    SUPPORTED_OPS = :+, :-, :*
    
    # currency symbols
    # use array to specify a HMTL entity
    @@symbols = {
      'USD' => '$',
      'AUD' => '$',
      'CAD' => '$',
      'HKD' => '$',
      'SGD' => '$',
      
      'EUR' => ['€', '&euro;'],
      'GBP' => ['£', '&pound;'],
      'JPY' => ['¥', '&yen;']
    }
    cattr_accessor :symbols
    
    # Takes a ActsAsMoney::Forex::Service object
    cattr_accessor :exchange_rate_service
    
    include Comparable
    
    def initialize(amount, currency='USD')
      currency = 'USD' if currency.nil?
      @amount, @currency = amount, currency
    end
    
    def units
      amount / 100
    end
    
    def cents_only
      amount % 100
    end
    
    def to_s(format=:plain)
      formatted = "#{units}.#{sprintf("%02d", cents_only)}"
      case format
      when :plain
        formatted
      when :code
        formatted << @currency
      when :symbol
        if symbol
          "#{symbol}#{formatted}"
        else
          to_s :code
        end
      when :html
        if html_entity
          "#{html_entity}#{formatted}"
        else
          to_s :code
        end
      end
    end
    
    def to_html
      to_s :html
    end
    
    def to_i
      amount
    end
    
    def ==(val)
      val.is_a?(Money) && self.currency == val.currency && self.to_i == val.to_i
    end

    def <=>(val)
      val = convert_to_own_currency(val)
      self.to_i <=> val.to_i
    end

    def /(val)
      val = convert_to_own_currency(val)
      i = self.to_i / val.to_i
      i += 1 if (self.to_i % val.to_i) != 0
      Money.new(i, self.currency)
    end
    
    def convert_to(new_currency)
      raise NoConversionAvailableError unless exchange_rate_service
      exchange_rate_service.exchange(self, new_currency)
    end

    def method_missing(method, *args, &block)
      if method.to_s =~ /^to_([A-Z]{3}$)/
        # to_XXX methods attempt a currency conversion
        convert_to($1)
      elsif SUPPORTED_OPS.include? method
        # supported maths operators attempt maths op
        do_math(method, args[0]) 
      else
        # the rest
        super(method, *args, &block)
      end
    end

    protected

    def do_math(op, val)
      # need to ensure rounding up occurs
      val = convert_to_own_currency(val)
      val = val.to_i if val.class == Money 
      Money.new self.to_i.send(op, val).ceil, self.currency
    end
    
    def convert_to_own_currency(val)
      if val.is_a?(Money) && val.currency != self.currency
        val.convert_to(self.currency)
      else
        val
      end
    end
    
    def symbol
      if symbol = @@symbols[currency]
        symbol.is_a?(String) ? symbol : symbol.first
      end
    end
    
    def html_entity
      if symbol = @@symbols[currency]
        symbol.is_a?(String) ? symbol : symbol.last
      end
    end
    
  end
  
  module ClassMethods
    
    # acts_as_money :price, :amount => :amount, :currency => :currency
    def acts_as_money(field, options={})
      options = { :amount => :amount, :currency => :currency }.merge(options)
      
      class_eval do
        define_method field do
          currency = options[:currency].is_a?(Symbol) ? send(options[:currency]) : options[:currency]
          
          if amount = send(options[:amount])
            Money.new(amount, currency)
          end
        end
        
        define_method "#{field}=".to_sym do |val|
          currency = options[:currency].is_a?(Symbol) ? send(options[:currency]) : options[:currency]
          
          val = Money.new(val, currency) unless val.is_a? Money
          write_attribute(options[:amount], val.amount)
          write_attribute(options[:currency], val.currency)
          return val
        end
      end
    end

  end
  
  module Extensions
    module Numeric
      
      def method_missing(meth)
        if meth.to_s =~ /^[A-Z]{3}$/
          Money.new((self * 100).round, meth.to_s)
        else
          super
        end
      end
      
    end
  end
  
end