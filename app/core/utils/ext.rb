module Blank
  def blank?
    respond_to?(:empty?) ? empty? : !self
  end
end

module NotNil
  def not_nil!
    raise "Value cannot be nil or blank at #{caller_locations(1,1)[0]}" if self.blank?
    self
  end
end

module NotBlank
  def not_blank!
    raise "Value cannot be nil or blank at #{caller_locations(1,1)[0]}" if self.blank?
    self
  end
end

class Object
  include NotNil
  include Blank
  include NotBlank
end