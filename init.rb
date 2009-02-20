ActiveRecord::Base.class_eval do
  include ActsAsMoney
end

Numeric.class_eval do
  include ActsAsMoney::Extensions::Numeric
end
