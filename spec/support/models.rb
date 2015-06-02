class Person < ActiveRecord::Base
  has_many :pets, inverse_of: :person
  has_many :pictures, as: :owner
end

class Pet < ActiveRecord::Base
  belongs_to :person, touch: true, inverse_of: :pets
end

class Picture < ActiveRecord::Base
  belongs_to :owner, polymorphic: true, touch: true

  before_save :raise_an_exception

  def raise_an_exception
    if name == "error"
      raise "Cannot save picture"
    else
      true
    end
  end
end
