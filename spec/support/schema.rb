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

end
