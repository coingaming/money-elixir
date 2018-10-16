defmodule Money do
  @moduledoc """

  Money amount converter.

  Converts money amounts with different currencies.

  """

  @enforce_keys [:amount, :currency_code, :currency_unit]
  defstruct [:amount, :currency_code, :currency_unit]

  @decimal_point "."

  @currency_config Money.Constants.currency_config()

  @doc """
  Converts amounts of money from strings, floats or integers to Money.

  ## Examples from strings with currency symbols as a separate argument

      iex> Money.to_money("123.456789", "EUR")
      %Money{amount: 12345679, currency_code: "EUR", currency_unit: "EUR"}

      iex> Money.to_money("123.456789", "BTC", "mBTC")
      %Money{amount: 12345679, currency_code: "BTC", currency_unit: "mBTC"}

      iex> Money.to_money("+123.+456789", "EUR")
      ** (ArgumentError) argument error

      iex> Money.to_money("-123.-456789", "EUR")
      ** (ArgumentError) argument error

      iex> Money.to_money("0.0000099999999", "EUR")
      %Money{amount: 1, currency_code: "EUR", currency_unit: "EUR"}

      iex> Money.to_money("-0.00001", "EUR")
      %Money{amount: -1, currency_code: "EUR", currency_unit: "EUR"}

  ## Examples from floats

      iex> Money.to_money(123.45, "EUR")
      %Money{amount: 12345000, currency_code: "EUR", currency_unit: "EUR"}

      iex> Money.to_money(123.45, "EUR", "cent")
      %Money{amount: 123450, currency_code: "EUR", currency_unit: "cent"}

      iex> Money.to_money(-1234.5678999, "EUR")
      %Money{amount: -123456790, currency_code: "EUR", currency_unit: "EUR"}

      iex> Money.to_money(0.0000099999999, "EUR")
      %Money{amount: 1, currency_code: "EUR", currency_unit: "EUR"}

      iex> Money.to_money(1.0e-5, "EUR")
      %Money{amount: 1, currency_code: "EUR", currency_unit: "EUR"}

      iex> Money.to_money(-0.00001, "EUR")
      %Money{amount: -1, currency_code: "EUR", currency_unit: "EUR"}

  ## Examples from integers

      iex> Money.to_money(12345, "EUR")
      %Money{amount: 1234500000, currency_code: "EUR", currency_unit: "EUR"}

      iex> Money.to_money(-12345, "EUR")
      %Money{amount: -1234500000, currency_code: "EUR", currency_unit: "EUR"}

  ## Examples with errors

      iex> Money.to_money("123.456!789", "EUR")
      ** (ArgumentError) argument error

      iex> Money.to_money("123!456!789", "EUR")
      ** (ArgumentError) argument error

      iex> Money.to_money("123.456.789", "EUR")
      ** (ArgumentError) argument error

      iex> Money.to_money("123.45", "Euro")
      ** (ArgumentError) Unsupported currency 'Euro'

  """
  Money.Constants.currency_config()
  |> Enum.each(fn({currency_code, %{units: units = %{}}}) ->
      units
      |> Enum.each(fn({currency_unit, %{}}) ->
          def switch_unit(money = %Money{currency_code: unquote(currency_code)}, unquote(currency_unit)) do
            %Money{money | currency_unit: unquote(currency_unit)}
          end
      end)
  end)




  @spec to_money(amount :: integer() | String.t | float(), currency_code :: String.t) :: %Money{}
  def to_money(amount, currency_code), do: to_money(amount, currency_code, currency_code)
  @spec to_money(amount :: integer() | String.t | float(), currency_code :: String.t, currency_unit :: String.t) :: %Money{}
  def to_money(string_amount, currency_code, currency_unit) when is_binary(string_amount) and
                                                                 is_binary(currency_code) and
                                                                 is_binary(currency_unit)
  do
    cond do
      String.contains?(string_amount, @decimal_point) ->
        string_amount
        |> :erlang.binary_to_float
        |> to_money(currency_code, currency_unit)
      true ->
        string_amount
        |> :erlang.binary_to_integer
        |> to_money(currency_code, currency_unit)
    end
  end

  def to_money(float_amount, currency_code, currency_unit) when is_float(float_amount) and
                                                 is_binary(currency_code) and
                                                 is_binary(currency_unit)
  do
    %{precision: precision, units: %{^currency_unit => %{shift: shift}}} =
      Map.get(@currency_config, currency_code) || raise ArgumentError, "Unsupported currency '#{currency_code}'"
    amount =
      float_amount
      |> :erlang.float_to_binary(decimals: precision - shift)
      |> String.replace(@decimal_point, "")
      |> String.to_integer
    %Money{amount: amount, currency_code: currency_code, currency_unit: currency_unit}
  end

  def to_money(integer_amount, currency_code, currency_unit) when is_integer(integer_amount) and
                                                                  is_binary(currency_code) and
                                                                  is_binary(currency_unit) do
    %{precision: precision, units: %{^currency_unit => %{shift: shift}}} =
      Map.get(@currency_config, currency_code) || raise ArgumentError, "Unsupported currency '#{currency_code}'"
    %Money{amount: integer_amount * pow10(precision - shift), currency_code: currency_code, currency_unit: currency_unit}
  end

  @doc """
  Converts from Money to string. When precision parameter is used function cuts off unneeded
  digits i.e. it works like Float.floor.

  ## Examples

      iex> Money.to_string(%Money{amount: 12_345_678, currency_code: "GBP", currency_unit: "GBP"})
      "123.45678"

      iex> Money.to_string(%Money{amount: 12_345_678, currency_code: "GBP", currency_unit: "cent"})
      "12345.678"

      iex> Money.to_string(%Money{amount: -12_345_678, currency_code: "PHP", currency_unit: "PHP"})
      "-123.45678"

      iex> Money.to_string(%Money{amount: 12_345_678, currency_code: "BTC", currency_unit: "BTC"})
      "0.12345678"

      iex> Money.to_string(%Money{amount: 100_000, currency_code: "EUR", currency_unit: "EUR"})
      "1.0"

      iex> Money.to_string(%Money{amount: 1_000, currency_code: "EUR", currency_unit: "EUR"})
      "0.01"

      iex> Money.to_string(%Money{amount: 999, currency_code: "EUR", currency_unit: "EUR"})
      "0.00999"

      iex> Money.to_string(%Money{amount: 100, currency_code: "EUR", currency_unit: "EUR"})
      "0.001"

      iex> Money.to_string(%Money{amount: 1, currency_code: "EUR", currency_unit: "EUR"})
      "0.00001"

      iex> Money.to_string(%Money{amount: 1, currency_code: "BTC", currency_unit: "BTC"})
      "0.00000001"

      iex> Money.to_string(%Money{amount: 0, currency_code: "BTC", currency_unit: "BTC"})
      "0.0"

      iex> Money.to_string(%Money{amount: 12345678901234567890123456789012345678901234567890, currency_code: "EUR", currency_unit: "EUR"})
      "123456789012345678901234567890123456789012345.6789"

      iex> Money.to_string(%Money{amount: 12345678901234567890123456789012345678901234567890, currency_code: "EUR", currency_unit: "cent"})
      "12345678901234567890123456789012345678901234567.89"

      iex> Money.to_string(%Money{amount: 12345, currency_code: "BTC", currency_unit: "uBTC"})
      "123.45"

      iex> Money.to_string(%Money{amount: 12345, currency_code: "BTC", currency_unit: "uBTC"},0)
      "123"

      iex> Money.to_string(%Money{amount: 12345, currency_code: "BTC", currency_unit: "uBTC"},1)
      "123.4"

      iex> Money.to_string(%Money{amount: 12345, currency_code: "BTC", currency_unit: "uBTC"},2)
      "123.45"

      iex> Money.to_string(%Money{amount: 12345, currency_code: "BTC", currency_unit: "uBTC"},3)
      "123.450"

      iex> Money.to_string(%Money{amount: 12345, currency_code: "Euro", currency_unit: "uBTC"},3)
      ** (ArgumentError) Unsupported currency 'Euro'

      iex> Money.to_string(%Money{amount: -5305, currency_code: "BTC", currency_unit: "BTC"})
      "-0.00005305"

  """
  @spec to_string(%Money{}, nil | non_neg_integer()) :: String.t
  def to_string(%Money{amount: amount, currency_code: currency_code, currency_unit: currency_unit},
                precision \\ nil) do
    %{precision: currency_precision, units: %{^currency_unit => %{shift: shift}}} =
      Map.get(@currency_config, currency_code) || raise ArgumentError, "Unsupported currency '#{currency_code}'"
    unit_precision = currency_precision - shift

    minus_sign = if amount >= 0, do: "", else: "-"

    {integer_string, fractional_string} =
      amount
      |> abs()
      |> Integer.to_string
      |> String.split_at(-unit_precision)

    minus_sign
    <>
    (integer_string
     |> String.pad_leading(1, "0"))
    <>
    cond do
      precision == 0 ->
        ""
      is_integer(precision) and precision > 0 ->
        @decimal_point
        <>
        (fractional_string
        |> String.pad_leading(unit_precision, "0")
        |> String.slice(0, precision)
        |> String.pad_trailing(precision, "0"))
      true ->
        @decimal_point
        <>
        (fractional_string
        |> String.pad_leading(unit_precision, "0")
        |> String.trim_trailing("0")
        |> String.pad_leading(1, "0"))
    end
  end

  @doc """
  Converts from Money to floats.

  ## Examples

      iex> Money.to_float(%Money{amount: 12_345_000, currency_code: "EUR", currency_unit: "EUR"})
      123.45

      iex> Money.to_float(%Money{amount: 12_345_678, currency_code: "EUR", currency_unit: "EUR"})
      123.45678

      iex> Money.to_float(%Money{amount: -12_345_000, currency_code: "EUR", currency_unit: "EUR"})
      -123.45

      iex> Money.to_float(%Money{amount: 123_450, currency_code: "EUR", currency_unit: "EUR"})
      1.2345

      iex> Money.to_float(%Money{amount: 123_456, currency_code: "EUR", currency_unit: "EUR"})
      1.23456

      iex> Money.to_float(%Money{amount: 123, currency_code: "EUR", currency_unit: "EUR"})
      0.00123

      iex> Money.to_float(%Money{amount: 1, currency_code: "EUR", currency_unit: "EUR"})
      1.0e-5

      iex> Money.to_float(%Money{amount: -5305, currency_code: "BTC", currency_unit: "BTC"})
      -5.305e-5

      iex> Money.to_float(%Money{amount: 0, currency_code: "EUR", currency_unit: "EUR"})
      0.0

      iex> Money.to_float(%Money{amount: 12345678901234567890123456789012345678901234567890, currency_code: "EUR", currency_unit: "EUR"})
      1.2345678901234567e44

  """
  @spec to_float(%Money{}) :: float()
  def to_float(%Money{} = money) do
    money
    |> __MODULE__.to_string
    |> :erlang.binary_to_float
  end

  @pow10_max 104
  Enum.reduce 0..@pow10_max, 1, fn int, acc ->
    def pow10(unquote(int)), do: unquote(acc)
    acc * 10
  end
  def pow10(int) when int > @pow10_max do
    pow10(@pow10_max) * pow10(int - @pow10_max)
  end
end
