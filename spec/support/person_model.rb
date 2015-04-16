require "active_model"

class PersonModel
  include ActiveModel
  include GlobalID::Identification

  attr_accessor :id

  def initialize(attributes = {})
    attributes.each { |name, value| send("#{name}=", value) }
  end

  def self.find(id)
    new :id => id
  end

  def ==(other)
    id == other.try(:id)
  end
end
