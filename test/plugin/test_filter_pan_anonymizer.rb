require_relative '../helper'
require 'fluent/test/driver/filter'

require 'fluent/plugin/filter_pan_anonymizer'

class PANAnonymizerFilterTest < Test::Unit::TestCase
  def setup
    Fluent::Test::setup
    @time = Fluent::Engine.now
  end

  CONFIG = %[
    <pan>
      formats /4\d{15}/
      checksum_algorithm luhn
      mask ***
    </pan>
    <pan>
      formats /4\d{15}/
      checksum_algorithm none
      mask ***
    </pan>
    <pan>
      formats /4019-\d{4}-\d{4}-\d{4}/
      checksum_algorithm luhn
      mask ***
    </pan>
    <pan>
      formats /4019\d{10}/, /4019-\d{4}-\d{4}-\d{4}/
      checksum_algorithm luhn
      mask ***
    </pan>
    ignore_keys ignore1, ignore2
  ]

  def create_driver(conf=CONFIG)
    Fluent::Test::Driver::Filter.new(Fluent::Plugin::PANAnonymizerFilter).configure(conf)
  end

  def filter(conf, messages)
    d = create_driver(conf)
    d.run(default_tag: 'test') do
      messages.each do |message|
        d.feed(message)
      end
    end
    d.filtered_records
  end

  sub_test_case 'configured with invalid configuration' do
    test 'empty configuration' do
      assert_raise(Fluent::ConfigError) do
        create_driver("")
      end
    end
    test '<pan></pan> is required' do
      conf = %[
      ]
			assert_raise(Fluent::ConfigError) do
			  create_driver(conf)
			end
		end
    test 'ok if <pan> exists' do
      conf = %[
			  <pan>
			  </pan>
      ]
			assert_nothing_raised(Fluent::ConfigError) do
		    create_driver(conf)
			end
    end
    test 'valid config' do
      conf = %[
			  <pan>
			  	formats /4\d{15}/
			  	checksum_algorithm luhn
			  	mask xxxx
			  </pan>
        ignore_keys key1, key2
      ]
			assert_nothing_raised(Fluent::ConfigError) do
		    create_driver(conf)
			end
    end
    test 'multi <pan> block' do
      conf = %[
			  <pan>
			  	formats /40192491\d{8}/
			  	checksum_algorithm luhn
			  	mask xxxx
			  </pan>
			  <pan>
			  	formats /40192492\d{8}/
			  	checksum_algorithm luhn
			  	mask xxxx
			  </pan>
        ignore_keys key1, key2
      ]
			assert_nothing_raised(Fluent::ConfigError) do
		    create_driver(conf)
			end
		end
    test 'multi <pan> block with multi formats fields' do
      conf = %[
			  <pan>
			  	formats /40192491\d{8}/, /4019-2491-\d{4}-\d{4}/
			  	checksum_algorithm luhn
			  	mask xxxx
			  </pan>
			  <pan>
			  	formats /40192492\d{8}/, /4019-2492-\d{4}-\d{4}/
			  	checksum_algorithm luhn
			  	mask xxxx
			  </pan>
        ignore_keys key1, key2
      ]
			assert_nothing_raised(Fluent::ConfigError) do
		    create_driver(conf)
			end
		end
	end

  test "aaaaaaaa" do
    conf = %[
      <pan>
        formats %r/4\\d{15}/
        checksum_algorithm luhn
        mask xxxx
      </pan>
    ]
    messages = [
      {
        "key": "9994019249331712145999"
      }
    ]
    expected = [
      {
        "key": "999xxxx999"
      }
    ]
    filtered = filter(conf, messages)
    assert_equal(expected, filtered)
  end
end
