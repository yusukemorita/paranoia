# paranoia本家には存在せず、forkした後に追加したテスト

require 'bundler/setup'
require 'active_record'
require 'minitest/autorun'
require 'paranoia'

test_framework = defined?(Minitest::Test) ? Minitest::Test : Minitest::Unit::TestCase

if ActiveRecord::Base.respond_to?(:raise_in_transactional_callbacks=)
  ActiveRecord::Base.raise_in_transactional_callbacks = true
end

class ParanoiaCustomTest < test_framework
  def setup
    connection = ActiveRecord::Base.connection
    cleaner = ->(source) {
      ActiveRecord::Base.connection.execute "DELETE FROM #{source}"
    }

    if ActiveRecord::VERSION::MAJOR < 5
      connection.tables.each(&cleaner)
    else
      connection.data_sources.each(&cleaner)
    end
  end

  def test_multiple_sentinel_values_are_applied
    # setup
    ActiveRecord::Base.connection.execute(
      "CREATE TABLE paranoid_model_with_multiple_sentinel_values (id INTEGER NOT NULL PRIMARY KEY, deleted_at DATETIME)"
    )

    # test
    deleted_at_nil = ParanoidModelWithMultipleSentinelValues.new(deleted_at: nil)
    assert_equal false, deleted_at_nil.destroyed?
 
    deleted_at_zero = ParanoidModelWithMultipleSentinelValues.new(deleted_at: DateTime.new(0).utc)
    assert_equal false, deleted_at_zero.destroyed?

    deleted_at_now = ParanoidModelWithMultipleSentinelValues.new(deleted_at: DateTime.now)
    assert_equal true, deleted_at_zero.destroyed?
  end
end

class ParanoidModelWithMultipleSentinelValues < ActiveRecord::Base
  acts_as_paranoid sentinel_values: [DateTime.new(0).utc, nil]
end
