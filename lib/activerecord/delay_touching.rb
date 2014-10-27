require "activerecord/delay_touching/version"
require "activerecord/delay_touching/state"

module ActiveRecord
  module DelayTouching
    extend ActiveSupport::Concern

    # Override ActiveRecord::Base#touch.
    def touch(name = nil)
      if self.class.delay_touching? && !try(:no_touching?)
        DelayTouching.add_record(self, name)
        true
      else
        super
      end
    end

    # These get added as class methods to ActiveRecord::Base.
    module ClassMethods
      # Lets you batch up your `touch` calls for the duration of a block.
      #
      # ==== Examples
      #
      #   # Touches Person.first once, not twice, when the block exits.
      #   ActiveRecord::Base.delay_touching do
      #     Person.first.touch
      #     Person.first.touch
      #   end
      #
      def delay_touching(&block)
        DelayTouching.call &block
      end

      # Are we currently executing in a delay_touching block?
      def delay_touching?
        DelayTouching.state.nesting > 0
      end
    end

    def self.state
      Thread.current[:delay_touching_state] ||= State.new
    end

    class << self
      delegate :add_record, to: :state
    end

    # Start delaying all touches. When done, apply them. (Unless nested.)
    def self.call
      state.nesting += 1
      begin
        yield
      ensure
        apply if state.nesting == 1
      end
    ensure
      # Decrement nesting even if `apply` raised an error.
      state.nesting -= 1
    end

    # Apply the touches that were delayed.
    def self.apply
      begin
        ActiveRecord::Base.transaction do
          state.records_by_attrs_and_class.each do |attr, classes_and_records|
            classes_and_records.each do |klass, records|
              touch_records attr, klass, records
            end
          end
        end
      end while state.more_records?
    ensure
      state.clear_records
    end

    # Touch the specified records--non-empty set of instances of the same class.
    def self.touch_records(attr, klass, records)
      attributes = records.first.send(:timestamp_attributes_for_update_in_model)
      attributes << attr if attr

      if attributes.present?
        current_time = records.first.send(:current_time_from_proper_timezone)
        changes = {}

        attributes.each do |column|
          column = column.to_s
          changes[column] = current_time
          records.each do |record|
            record.instance_eval do
              write_attribute column, current_time
              @changed_attributes.except!(*changes.keys)
            end
          end
        end

        klass.unscoped.where(klass.primary_key => records).update_all(changes)
      end
      state.updated attr, records
      records.each { |record| record.run_callbacks(:touch) }
    end
  end
end

ActiveRecord::Base.include ActiveRecord::DelayTouching
