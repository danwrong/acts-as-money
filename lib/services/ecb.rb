module ActsAsMoney
  # responsible for fetching exchange rates periodically and attaching them into Money
  # See: http://www.ecb.int/stats/eurofxref/eurofxref-daily.xml
  # for XML data feed based on EUR
  module Services
    
    # To fetch forex from ECB service and provide to Money class
    class ECB < ActsAsMoney::Forex::Service
      
      @@rates = {
        'EUR' => 1.0
      }
      
      URL = URI::parse('http://www.ecb.int/stats/eurofxref/eurofxref-daily.xml')
      
      def initialize(options={})
        @options = { :expire_every => 1.days }.merge(options)
        fetch_exchange_rates
      end
      
      def base_currency
        'EUR'
      end
      
      def rates
        fetch_exchange_rates if Time.now > @last_fetch + @options[:expire_every]
        @@rates
      end
      
      protected
      
      def fetch_exchange_rates
        @last_fetch = Time.now
        
        forex_doc = Net::HTTP.get(URL)
        forex_xml = REXML::Document.new(forex_doc)
        
        forex_xml.each_element('//Cube[@currency]') do |element|
          @@rates[element.attributes['currency']] = element.attributes['rate'].to_f
        end
      rescue
        # simply do nothing if the update fails - just log the error
        RAILS_DEFAULT_LOGGER.info('Error retrieving currency from ECB') if RAILS_DEFAULT_LOGGER
      end
      
    end
    
  end
end