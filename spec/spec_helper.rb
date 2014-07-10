$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'active_record'
require 'activerecord/delay_touching'
require 'timecop'

ActiveRecord::Base.establish_connection adapter: "sqlite3", database: ":memory:"

load File.dirname(__FILE__) + '/support/schema.rb'
require File.dirname(__FILE__) + '/support/models.rb'
