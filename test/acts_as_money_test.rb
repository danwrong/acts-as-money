require 'rubygems'
require 'active_support'
require File.dirname(__FILE__) + '/../lib/acts_as_money'
require 'test/unit'

Fixnum.class_eval do
  include ActsAsMoney::Extensions::Fixnum
end

class MockForex < ActsAsMoney::Forex::Service
  
  @@rates = {
    'USD' => 1.0,
    'GBP' => 0.498,
    'AUD' => 1.176
  }
  
  def base_currency
    'USD'
  end
  
  def rates
    @@rates
  end
  
end

class ActsAsMoneyTest < Test::Unit::TestCase
  include ActsAsMoney
  
  def setup
    Money.exchange_rate_service = MockForex.new
  end
  
  def test_should_use_USD_as_default
    money = Money.new 100
    assert_equal 'USD', money.currency
  end
  
  def test_should_return_units_and_cents_correctly
    money = Money.new 340
    assert_equal 3, money.units
    assert_equal 40, money.cents_only
  end
  
  def test_should_alias_cents_to_amount
    money = Money.new 340
    assert_equal money.amount, money.cents
  end
  
  def test_should_return_to_s_formats_correctly
    money = Money.new 340, 'GBP'
    assert_equal '3.40', money.to_s(:plain)
    assert_equal '£3.40', money.to_s(:symbol)
    assert_equal '3.40GBP', money.to_s(:code)
    assert_equal '&pound;3.40', money.to_html
  end
  
  def test_if_not_symbol_given_to_s_symbol_reverts_to_code
    money = Money.new 453, 'THB'
    assert_equal '4.53THB', money.to_s(:symbol)
  end
  
  def test_to_i_should_return_amount
    money = Money.new 567567
    assert_equal money.amount, money.to_i
  end
  
  def test_money_with_same_amount_and_same_currency_should_be_equal
    m1 = Money.new 120, 'GBP'
    m2 = Money.new 120, 'GBP'
    m3 = Money.new 120, 'AUD'
    
    assert m1 == m2
    assert m1 != m3
  end
  
  def test_money_with_same_currencies_are_comparible
    assert Money.new(200) > Money.new(100)
    assert Money.new(5) < Money.new(234334) 
  end
  
  def test_if_conversion_service_not_present_raises_error
    Money.exchange_rate_service = nil
    assert_raises NoConversionAvailableError do
      Money.new(400).convert_to('GBP')
    end
  end
  
  def test_if_forex_service_available_then_conversion_is_made
    m = Money.new 100
    m_as_gbp = m.convert_to('GBP')
    assert_kind_of Money, m_as_gbp
    assert_equal 'GBP', m_as_gbp.currency
  end
  
  def test_should_perform_simple_maths_with_numbers
    assert_equal 10.USD, 20.USD / 2
    assert_equal 20.GBP, 5.GBP * 4
    assert_equal 15.AUD, 5.AUD + 1000
    assert_equal 10.JPY, 11.JPY - 100
  end
  
  def test_should_perform_simple_maths_with_other_money_of_the_same_currency
    assert_equal 10.USD, 8.USD + 2.USD
    assert_equal 24.GBP, 30.GBP - 6.GBP
  end
  
  def test_should_raise_if_maths_with_different_currency_and_service_not_available
    Money.exchange_rate_service = nil
    assert_raises NoConversionAvailableError do
      10.GBP + 5.USD
    end
  end
  
  def test_should_perform_simple_maths_with_other_money_of_different_currency_if_service_available
    m = 10.USD + 5.GBP
    assert_equal 'USD', m.currency
    assert_equal 2005, m.amount
    
    m2 = 20.GBP - 4.AUD
    assert_equal 'GBP', m2.currency
    assert_equal 1830, m2.amount
  end
  
  def test_should_allow_conversion_using_shortcut_methods_if_service_available
    assert_equal Money.new(20081), 100.GBP.to_USD
  end
  
end

class FixnumExtTest < Test::Unit::TestCase
  
  def test_currency_shortcuts_work_correctly
    m = 10.USD
    assert_equal 10, m.units
    assert_equal 0, m.cents_only
    assert_equal 'USD', m.currency
  end
  
end

class ForexTest < Test::Unit::TestCase
  
  def setup
    @service = MockForex.new
    @some_gbp = 100.GBP
    @some_aud = 50.AUD
  end
  
  def test_if_conversion_not_available_then_error_raised
    assert_raises ActsAsMoney::NoConversionAvailableError do
      @service.exchange(@some_gbp, 'XXX')
    end
  end
  
  def test_exchange_exchanges_money_correctly
    usd = @service.exchange(@some_gbp, 'USD')
    assert_equal 'USD', usd.currency
    assert_equal 20081, usd.amount
    
    gbp = @service.exchange(@some_aud, 'GBP')
    assert_equal 2118, gbp.amount
  end 
  
end
