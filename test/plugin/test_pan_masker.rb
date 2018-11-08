require 'helper'
require 'fluent/plugin/pan/masker'

# NOTE: The card number in the test doesn't exist in the world!

class PANMaskerTest < Test::Unit::TestCase

  sub_test_case "valid?" do
    test "valid digits" do
      valid_card_number = [4, 0, 1, 9, 2, 4, 9, 3, 3, 1, 7, 1, 2, 1, 4, 5]
      f = Fluent::PAN::Masker.new(//, :luhn, "")
      assert_equal(true, f.valid?(valid_card_number))
    end

    test "invalid digits" do
      invalid_card_number = [4, 0, 1, 9, 2, 4, 9, 3, 9, 9, 9, 9, 9, 9, 9, 9]
      f = Fluent::PAN::Masker.new(//, :luhn, "")
      assert_equal(false, f.valid?(invalid_card_number))
    end

    test "always true when checksum algorithm is none" do
      valid_card_number = [4, 0, 1, 9, 2, 4, 9, 3, 3, 1, 7, 1, 2, 1, 4, 5]
      f = Fluent::PAN::Masker.new(//, :none, "")
      assert_equal(true, f.valid?(valid_card_number))

      invalid_card_number = [4, 0, 1, 9, 2, 4, 9, 3, 9, 9, 9, 9, 9, 9, 9, 9]
      f = Fluent::PAN::Masker.new(//, :none, "")
      assert_equal(true, f.valid?(invalid_card_number))

      invalid_card_number = [9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9]
      f = Fluent::PAN::Masker.new(//, :none, "")
      assert_equal(true, f.valid?(invalid_card_number))
    end
  end

  sub_test_case "numerals_mask?" do
    test "true" do
      mask = 0
      f = Fluent::PAN::Masker.new(//, :none, mask)
      assert_equal(true, f.numerals_mask?)

      mask = 00
      f = Fluent::PAN::Masker.new(//, :none, mask)
      assert_equal(true, f.numerals_mask?)

      mask = 100
      f = Fluent::PAN::Masker.new(//, :none, mask)
      assert_equal(true, f.numerals_mask?)

      mask = "0"
      f = Fluent::PAN::Masker.new(//, :none, mask)
      assert_equal(true, f.numerals_mask?)

      mask = "00"
      f = Fluent::PAN::Masker.new(//, :none, mask)
      assert_equal(true, f.numerals_mask?)

      mask = "100"
      f = Fluent::PAN::Masker.new(//, :none, mask)
      assert_equal(true, f.numerals_mask?)
    end

    test "false" do
      mask = "*"
      f = Fluent::PAN::Masker.new(//, :none, mask)
      assert_equal(false, f.numerals_mask?)

      mask = "*00"
      f = Fluent::PAN::Masker.new(//, :none, mask)
      assert_equal(false, f.numerals_mask?)

      mask = "100*"
      f = Fluent::PAN::Masker.new(//, :none, mask)
      assert_equal(false, f.numerals_mask?)
    end
  end

  sub_test_case "mask_if_pan_found?" do
    test "with numerals string mask" do
      mask = "0000000000000000"
      f = Fluent::PAN::Masker.new(/4\d{15}/, :luhn, mask)

      filtered = f.mask_if_found_pan("4019249331712145")
      assert_equal(String, filtered.class)
      assert_equal("#{mask}", filtered)

      filtered = f.mask_if_found_pan("XXXX4019249331712145XXXX")
      assert_equal(String, filtered.class)
      assert_equal("XXXX#{mask}XXXX", filtered)

      filtered = f.mask_if_found_pan(4019249331712145)
      assert_equal(Integer, filtered.class)
      assert_equal("#{mask}".to_i, filtered)

      filtered = f.mask_if_found_pan(140192493317121459)
      assert_equal(Integer, filtered.class)
      assert_equal("1#{mask}9".to_i, filtered)
    end

    test "with numerals mask" do
      mask = 4019111111111111
      f = Fluent::PAN::Masker.new(/4\d{15}/, :luhn, mask)

      filtered = f.mask_if_found_pan("4019249331712145")
      assert_equal(String, filtered.class)
      assert_equal("#{mask}", filtered)

      filtered = f.mask_if_found_pan("XXXX4019249331712145XXXX")
      assert_equal(String, filtered.class)
      assert_equal("XXXX#{mask}XXXX", filtered)

      filtered = f.mask_if_found_pan(4019249331712145)
      assert_equal(Integer, filtered.class)
      assert_equal("#{mask}".to_i, filtered)

      filtered = f.mask_if_found_pan(140192493317121459)
      assert_equal(Integer, filtered.class)
      assert_equal("1#{mask}9".to_i, filtered)
    end

    test "with 0000000000000000 mask" do
      mask = 0000000000000000
      f = Fluent::PAN::Masker.new(/4\d{15}/, :luhn, mask)

      filtered = f.mask_if_found_pan("4019249331712145")
      assert_equal(String, filtered.class)
      assert_equal("0", filtered)

      filtered = f.mask_if_found_pan("XXXX4019249331712145XXXX")
      assert_equal(String, filtered.class)
      assert_equal("XXXX0XXXX", filtered)

      filtered = f.mask_if_found_pan(4019249331712145)
      assert_equal(Integer, filtered.class)
      assert_equal(0, filtered)

      filtered = f.mask_if_found_pan(140192493317121459)
      assert_equal(Integer, filtered.class)
      assert_equal(109, filtered)
    end

    test "with string mask" do
      mask = "****"
      f = Fluent::PAN::Masker.new(/4\d{15}/, :luhn, mask)

      filtered = f.mask_if_found_pan("4019249331712145")
      assert_equal(String, filtered.class)
      assert_equal("#{mask}", filtered)

      filtered = f.mask_if_found_pan("XXXX4019249331712145XXXX")
      assert_equal(String, filtered.class)
      assert_equal("XXXX#{mask}XXXX", filtered)

      filtered = f.mask_if_found_pan(4019249331712145)
      assert_equal(Integer, filtered.class)
      assert_equal(4019249331712145, filtered)

      filtered = f.mask_if_found_pan(140192493317121459)
      assert_equal(Integer, filtered.class)
      assert_equal(140192493317121459, filtered)
    end

    test "with string mask and force: true" do
      mask = "****"
      f = Fluent::PAN::Masker.new(/4\d{15}/, :luhn, mask, force: true)

      filtered = f.mask_if_found_pan("4019249331712145")
      assert_equal(String, filtered.class)
      assert_equal("#{mask}", filtered)

      filtered = f.mask_if_found_pan("XXXX4019249331712145XXXX")
      assert_equal(String, filtered.class)
      assert_equal("XXXX#{mask}XXXX", filtered)

      filtered = f.mask_if_found_pan(4019249331712145)
      assert_equal(String, filtered.class)
      assert_equal("#{mask}", filtered)

      filtered = f.mask_if_found_pan(140192493317121459)
      assert_equal(String, filtered.class)
      assert_equal("1#{mask}9", filtered)
    end
  end
end
