defmodule Money.MoneyTest do
  use ExUnit.Case, async: true

  test "Money.to_float" do
    assert Money.to_float(%Money{amount: 12_345_000, currency_code: "EUR", currency_unit: "EUR"}) == 123.45
    assert Money.to_float(%Money{amount: 12_345_678, currency_code: "EUR", currency_unit: "EUR"}) == 123.45678
    assert Money.to_float(%Money{amount: -12_345_000, currency_code: "EUR", currency_unit: "EUR"}) == -123.45
    assert Money.to_float(%Money{amount: 123_450, currency_code: "EUR", currency_unit: "EUR"}) == 1.2345
    assert Money.to_float(%Money{amount: 123_456, currency_code: "EUR", currency_unit: "EUR"}) == 1.23456
    assert Money.to_float(%Money{amount: 123, currency_code: "EUR", currency_unit: "EUR"}) == 0.00123
    assert Money.to_float(%Money{amount: 1, currency_code: "EUR", currency_unit: "EUR"}) == 1.0e-5
    assert Money.to_float(%Money{amount: 0, currency_code: "EUR", currency_unit: "EUR"}) == 0.0
    assert Money.to_float(%Money{amount: 12345678901234567890123456789012345678901234567890, currency_code: "EUR", currency_unit: "EUR"}) ==
      1.2345678901234567e44
    assert Money.to_float(%Money{amount: 12345678901234567890123456789012345678901234567890, currency_code: "EUR", currency_unit: "cent"}) ==
      1.2345678901234568e46
  end

  test "Money.to_string" do
    assert Money.to_string(%Money{amount: 12_345_678, currency_code: "GBP", currency_unit: "GBP"}) == "123.45678"
    assert Money.to_string(%Money{amount: 12_345_678, currency_code: "GBP", currency_unit: "cent"}) == "12345.678"
    assert Money.to_string(%Money{amount: -12_345_678, currency_code: "PHP", currency_unit: "PHP"}) == "-123.45678"
    assert Money.to_string(%Money{amount: 12_345_678, currency_code: "BTC", currency_unit: "BTC"}) == "0.12345678"
    assert Money.to_string(%Money{amount: 100_000, currency_code: "EUR", currency_unit: "EUR"}) == "1.0"
    assert Money.to_string(%Money{amount: 1_000, currency_code: "EUR", currency_unit: "EUR"}) == "0.01"
    assert Money.to_string(%Money{amount: 999, currency_code: "EUR", currency_unit: "EUR"}) == "0.00999"
    assert Money.to_string(%Money{amount: 100, currency_code: "EUR", currency_unit: "EUR"}) == "0.001"
    assert Money.to_string(%Money{amount: 1, currency_code: "EUR", currency_unit: "EUR"}) == "0.00001"
    assert Money.to_string(%Money{amount: 1, currency_code: "BTC", currency_unit: "BTC"}) == "0.00000001"
    assert Money.to_string(%Money{amount: 0, currency_code: "BTC", currency_unit: "BTC"}) == "0.0"
    assert Money.to_string(%Money{amount: 12345678901234567890123456789012345678901234567890, currency_code: "EUR", currency_unit: "EUR"}) ==
      "123456789012345678901234567890123456789012345.6789"
    assert Money.to_string(%Money{amount: 12345678901234567890123456789012345678901234567890, currency_code: "EUR", currency_unit: "cent"}) ==
      "12345678901234567890123456789012345678901234567.89"
  end

  test "Money.to_money" do
    assert Money.to_money("123.456789", "EUR") ==
      %Money{amount: 12345679, currency_code: "EUR", currency_unit: "EUR"}
    assert Money.to_money("123.456789", "BTC", "mBTC") ==
      %Money{amount: 12345679, currency_code: "BTC", currency_unit: "mBTC"}
    assert Money.to_money("0.0000099999999", "EUR") ==
      %Money{amount: 1, currency_code: "EUR", currency_unit: "EUR"}
    assert Money.to_money("-0.00001", "EUR") ==
      %Money{amount: -1, currency_code: "EUR", currency_unit: "EUR"}
    assert Money.to_money(123.45, "EUR") ==
      %Money{amount: 12345000, currency_code: "EUR", currency_unit: "EUR"}
    assert Money.to_money(123.45, "EUR", "cent") ==
      %Money{amount: 123450, currency_code: "EUR", currency_unit: "cent"}
    assert Money.to_money(-1234.5678999, "EUR") ==
      %Money{amount: -123456790, currency_code: "EUR", currency_unit: "EUR"}
    assert Money.to_money(0.0000099999999, "EUR") ==
      %Money{amount: 1, currency_code: "EUR", currency_unit: "EUR"}
    assert Money.to_money(1.0e-5, "EUR") ==
      %Money{amount: 1, currency_code: "EUR", currency_unit: "EUR"}
    assert Money.to_money(-0.00001, "EUR") ==
      %Money{amount: -1, currency_code: "EUR", currency_unit: "EUR"}
    assert Money.to_money(12345, "EUR") ==
      %Money{amount: 1234500000, currency_code: "EUR", currency_unit: "EUR"}
    assert Money.to_money(-12345, "EUR") ==
      %Money{amount: -1234500000, currency_code: "EUR", currency_unit: "EUR"}
    assert_raise(ArgumentError, fn -> Money.to_money("123.456!789", "EUR") end)
    assert_raise(ArgumentError, fn -> Money.to_money("123!456!789", "EUR") end)
    assert_raise(ArgumentError, fn -> Money.to_money("123.456.789", "EUR") end)
    assert_raise(ArgumentError, fn -> Money.to_money("+123.+456789", "EUR") end)
    assert_raise(ArgumentError, fn -> Money.to_money("123.45", "SomeUnknownCurrency") end)
    assert_raise(ArgumentError, fn -> Money.to_money("-123.-456789", "EUR") end)
  end

  test "Money.from_cent" do
    assert Money.from_cent(12_345, "EUR") ==
      %Money{amount: 12345000, currency_code: "EUR", currency_unit: "cent"}
    assert Money.from_cent("12345", "EUR") ==
      %Money{amount: 12345000, currency_code: "EUR", currency_unit: "cent"}
 end

  test "Money.to_cent" do
    assert Money.to_cent(%Money{amount: 12_345_000, currency_code: "EUR", currency_unit: "EUR"}) == 12_345
    assert Money.to_cent(%Money{amount: 12_345_678, currency_code: "EUR", currency_unit: "EUR"}) == 12_346
  end
end
