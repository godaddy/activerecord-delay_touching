class Person < ActiveRecord::Base
  has_many :pets, inverse_of: :person
end

class Pet < ActiveRecord::Base
  belongs_to :person, touch: true, inverse_of: :pets
end
