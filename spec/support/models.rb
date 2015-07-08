class Person < ActiveRecord::Base
  has_many :pets, inverse_of: :person
end

class Pet < ActiveRecord::Base
  belongs_to :person, touch: true, inverse_of: :pets
end

class Post < ActiveRecord::Base
  has_many :comments, dependent: :destroy
end

class User < ActiveRecord::Base
  has_many :comments, dependent: :destroy
end

class Comment < ActiveRecord::Base
  belongs_to :post, touch: true
  belongs_to :user, touch: true
end
