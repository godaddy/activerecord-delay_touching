class Person < ActiveRecord::Base
  has_many :pets, inverse_of: :person
end

class Pet < ActiveRecord::Base
  belongs_to :person, touch: true, inverse_of: :pets
end

class Post < ActiveRecord::Base
  has_many :comments, dependent: :destroy

  has_many :tag_relationships, dependent: :destroy
  has_many :tags, through: :tag_relationships
end

class User < ActiveRecord::Base
  has_many :comments, dependent: :destroy
end

class Comment < ActiveRecord::Base
  belongs_to :post, touch: true
  belongs_to :user, touch: true
end

class Tag < ActiveRecord::Base
  has_many :tag_relationships, dependent: :destroy
  has_many :posts, through: :tag_relationships
end

class TagRelationship < ActiveRecord::Base
  belongs_to :tag, touch: true
  belongs_to :post
end