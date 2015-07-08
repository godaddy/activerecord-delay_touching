ActiveRecord::Schema.define do
  self.verbose = false

  create_table :people, :force => true do |t|
    t.string :name

    t.timestamps
  end

  create_table :pets, :force => true do |t|
    t.string :name
    t.integer :person_id
    t.datetime :neutered_at
    t.datetime :fed_at

    t.timestamps
  end

  create_table :posts, force: true do |t|
    t.timestamps null: false
  end

  create_table :users, force: true do |t|
    t.timestamps null: false
  end

  create_table :comments, force: true do |t|
    t.integer :post_id
    t.integer :user_id
    t.timestamps null: false
  end

end
