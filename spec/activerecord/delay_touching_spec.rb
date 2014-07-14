require 'spec_helper'

describe Activerecord::DelayTouching do
  let(:person) { Person.create name: "Rosey" }
  let(:pet1) { Pet.create(name: "Bones") }
  let(:pet2) { Pet.create(name: "Ema") }

  it 'has a version number' do
    expect(Activerecord::DelayTouching::VERSION).not_to be nil
  end

  it 'touch returns true' do
    ActiveRecord::Base.delay_touching do
      expect(person.touch).to eq(true)
    end
  end

  it 'consolidates touches on a single record' do
    expect_updates ["people"] do
      ActiveRecord::Base.delay_touching do
        person.touch
        person.touch
      end
    end
  end

  it 'sets updated_at on the in-memory instance when it eventually touches the record' do
    original_time = new_time = nil

    Timecop.freeze(2014, 7, 4, 12, 0, 0) do
      original_time = Time.current
      person.touch
    end

    Timecop.freeze(2014, 7, 10, 12, 0, 0) do
      new_time = Time.current
      ActiveRecord::Base.delay_touching do
        person.touch
        expect(person.updated_at).to eq(original_time)
        expect(person.changed?).to be_falsey
      end
    end

    expect(person.updated_at).to eq(new_time)
    expect(person.changed?).to be_falsey
  end

  it 'does not mark the instance as changed when touch is called' do
    ActiveRecord::Base.delay_touching do
      person.touch
      expect(person).not_to be_changed
    end
  end

  it 'consolidates touches for all instances in a single table' do
    expect_updates ["pets"] do
      ActiveRecord::Base.delay_touching do
        pet1.touch
        pet2.touch
      end
    end
  end

  it 'does nothing if no_touching is on' do
    if ActiveRecord::Base.respond_to?(:no_touching)
      expect_updates [] do
        ActiveRecord::Base.no_touching do
          ActiveRecord::Base.delay_touching do
            person.touch
          end
        end
      end
    end
  end

  it 'only applies touches for which no_touching is off' do
    if Person.respond_to?(:no_touching)
      expect_updates ["pets"] do
        Person.no_touching do
          ActiveRecord::Base.delay_touching do
            person.touch
            pet1.touch
          end
        end
      end
    end
  end

  it 'does not apply nested touches if no_touching was turned on inside delay_touching' do
    if ActiveRecord::Base.respond_to?(:no_touching)
      expect_updates [ "people" ] do
        ActiveRecord::Base.delay_touching do
          person.touch
          ActiveRecord::Base.no_touching do
            pet1.touch
          end
        end
      end
    end
  end

  it 'can update nonstandard columns' do
    expect_updates [ "pets" => [ "updated_at", "neutered_at" ] ] do
      ActiveRecord::Base.delay_touching do
        pet1.touch :neutered_at
      end
    end
  end

  it 'splits up nonstandard column touches and standard column touches' do
    expect_updates [ { "pets" => [ "updated_at", "neutered_at" ]  }, { "pets" => [ "updated_at" ] } ] do
      ActiveRecord::Base.delay_touching do
        pet1.touch :neutered_at
        pet2.touch
      end
    end
  end

  it 'can update multiple nonstandard columns of a single record in different calls to touch' do
    expect_updates [ { "pets" => [ "updated_at", "neutered_at" ] }, { "pets" => [ "updated_at", "fed_at" ] } ] do
      ActiveRecord::Base.delay_touching do
        pet1.touch :neutered_at
        pet1.touch :fed_at
      end
    end
  end

  context 'touch: true' do
    before do
      person.pets << pet1
      person.pets << pet2
    end

    it 'consolidates touch: true touches' do
      expect_updates [ "pets", "people" ] do
        ActiveRecord::Base.delay_touching do
          pet1.touch
          pet2.touch
        end
      end
    end

    it 'does not touch the owning record via touch: true if it was already touched explicitly' do
      expect_updates [ "pets", "people" ] do
        ActiveRecord::Base.delay_touching do
          person.touch
          pet1.touch
          pet2.touch
        end
      end
    end
  end

  def expect_updates(tables)
    expected_sql = tables.map do |entry|
      if entry.kind_of?(Hash)
        entry.map do |table, columns|
          Regexp.new(%Q{UPDATE "#{table}" SET #{columns.map { |column| %Q{"#{column}" =.+} }.join(", ") } })
        end
      else
        Regexp.new(%Q{UPDATE "#{entry}" SET "updated_at" = })
      end
    end.flatten
    expect(ActiveRecord::Base.connection).to receive(:update).exactly(expected_sql.length).times do |stmt, _, _|
      index = expected_sql.index { |sql| stmt.to_sql =~ sql}
      expect(index).to be, "An unexpected touch occurred: #{stmt.to_sql}"
      expected_sql.delete_at(index)
    end

    yield

    expect(expected_sql).to be_empty, "Some of the expected updates were not executed."
  end
end
