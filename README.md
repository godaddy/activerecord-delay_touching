# Activerecord::DelayTouching

Batch up your ActiveRecord "touch" operations for better performance.

When you want to invalidate a cache in Rails, you use `touch: true`. But when
you modify a bunch of records that all `belong_to` the same owning record, that record
will be touched N times. It's incredibly slow.

With this gem, all `touch` operations are consolidated into as few database
round-trips as possible. Instead of N touches you get 1 touch.

## Installation

Add this line to your application's Gemfile:

    gem 'activerecord-delay_touching'

And then execute:

    $ bundle

Or install it yourself:

    $ gem install activerecord-delay_touching

## Usage

The setup:

    class Person < ActiveRecord::Base
      has_many :pets
      accepts_nested_attributes_for :pets
    end
    
    class Pet < ActiveRecord::Base
      belongs_to :person, touch: true
    end
    
Without `delay_touching`, this simple `update` in the controller calls
`@person.touch` N times, where N is the number of pets that were updated
via nested attributes. That's N-1 unnecessary round-trips to the database:

    class PeopleController < ApplicationController
      def update
        ...
        #
        @person.update(person_params)
        ...
      end
    end
    
    # SQL (0.1ms)  UPDATE "people" SET "updated_at" = '2014-07-09 19:48:07.137158' WHERE "people"."id" = 1
    # SQL (0.1ms)  UPDATE "people" SET "updated_at" = '2014-07-09 19:48:07.138457' WHERE "people"."id" = 1
    # SQL (0.1ms)  UPDATE "people" SET "updated_at" = '2014-07-09 19:48:07.140088' WHERE "people"."id" = 1

With `delay_touching`, @person is touched only once:

    ActiveRecord::Base.delay_touching do
      @person.update(person_params)
    end

    # SQL (0.1ms)  UPDATE "people" SET "updated_at" = '2014-07-09 19:48:07.140088' WHERE "people"."id" = 1

## Consolidates Touches Per Table

In the following example, a person gives his pet to another person. ActiveRecord
automatically touches the old person and the new person.  With `delay_touching`,
this will only make a *single* round-trip to the database, setting `updated_at`
for all Person records in a single SQL UPDATE statement. Not a big deal when there are
only two touches, but when you're updating records en masse and have a cascade
of hundreds touches, it really is a big deal.

    class Pet < ActiveRecord::Base
      belongs_to :person, touch: true

      def give(to_person)
        ActiveRecord::Base.delay_touching do
          self.person = to_person
          save! # touches old person and new person in a single SQL UPDATE.
        end
      end
    end

## Cascading Touches

When `delay_touch` runs through and touches everything, it captures additional
`touch` calls that might be called as side-effects. (E.g., in `after_touch`
handlers.) Then it makes a second pass, batching up those touches as well.

It keeps doing this until there are no more touches, or until the sun swallows
up the earth. Whichever comes first.

## Gotchas

Things to note:

  * `after_touch` callbacks are still fired for every instance, but not until the block is exited. 
    And they won't happen in the same order as they would if you weren't batching up your touches.
  * If you call person1.touch and then person2.touch, and they are two separate instances
    with the same id, only person1's `after_touch` handler will be called.

## Contributing

1. Fork it ( https://github.com/godaddy/activerecord-delay_touching/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
