require "activerecord/delay_touching/version"

module ActiveRecord
  module DelayTouching

    # Tracking of the touch state. This class has no class-level data, so you can
    # store per-thread instances in thread-local variables.
    class State
      attr_accessor :nesting

      def initialize
        @records = Hash.new { Set.new }
        @already_updated_records = Hash.new { Set.new }
        @nesting = 0
      end

      def updated(attr, records)
        @records[attr].subtract records
        @records.delete attr if @records[attr].empty?
        @already_updated_records[attr] += records
      end

      # Return the records grouped by the attributes that were touched, and by class:
      # [
      #   [
      #     nil, { Person => [ person1, person2 ], Pet => [ pet1 ] }
      #   ],
      #   [
      #     :neutered_at, { Pet => [ pet1 ] }
      #   ],
      # ]
      def records_by_attrs_and_class
        @records.map { |attrs, records| [attrs, records.group_by(&:class)] }
      end

      def more_records?
        @records.present?
      end

      def add_record(record, *columns)
        columns << nil if columns.empty? #if no arguments are passed, we will use nil to infer default column
        columns.each do |column|
          @records[column] += [ record ] unless @already_updated_records[column].include?(record)
        end
      end

      def clear_records
        @records.clear
        @already_updated_records.clear
      end

      # If we don't do this then an infinite loop is possible due to how 
      # Set#subtract and ActiveRecord::Core#== work internally, ActiveRecord lazily syncs
      # transaction state after rollback, which may change in-memory state of key objects,
      # which requires that the hash be rekeyed.
      def remove_unpersisted_records!
        @records.each do |attr, set|
          set.each(&:persisted?)
          set.instance_variable_get(:@hash).rehash
          set.keep_if(&:persisted?)
          @records.delete attr if set.empty?
        end
      end
    end
  end
end
