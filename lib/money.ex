defmodule Money do
  @moduledoc """

  Money amount converter.

  Converts money amounts with different currencies.

  """

  @enforce_keys [:amount, :currency_code]
  defstruct [:amount, :currency_code]

  @currency_config Application.app_dir(:ih_money, "priv/currency-config/config.json")
                   |> File.read!
                   |> Poison.decode!(keys: :atoms)

  @currency_code_map Enum.reduce(@currency_config, %{}, fn(%{code: code} = currency, acc) ->
    Map.put(acc, code, currency)
  end)

  @decimal_point "."

  @doc """
  Returns raw currencies config
  """
  
  def raw_config, do: @currency_config

  @doc """
  Converts amounts of money from strings, floats or integers with currency symbols to Money.

  ## Examples from strings with currency symbols inside

      iex> Money.to_money("$123.45")
      %Money{amount: 12345000, currency_code: "USD"}

      iex> Money.to_money("$123")
      %Money{amount: 12300000, currency_code: "USD"}

      iex> Money.to_money("$-123.45")
      %Money{amount: -12345000, currency_code: "USD"}

  ## Examples from strings with currency symbols as a separate argument

      iex> Money.to_money("123.456789", "EUR")
      %Money{amount: 12345679, currency_code: "EUR"}

      iex> Money.to_money("+123.+456789", "EUR")
      ** (ArgumentError) argument error

      iex> Money.to_money("-123.-456789", "EUR")
      ** (ArgumentError) argument error

      iex> Money.to_money("0.0000099999999", "EUR")
      %Money{amount: 1, currency_code: "EUR"}

      iex> Money.to_money("-0.00001", "EUR")
      %Money{amount: -1, currency_code: "EUR"}

  ## Examples from floats

      iex> Money.to_money(123.45, "EUR")
      %Money{amount: 12345000, currency_code: "EUR"}

      iex> Money.to_money(-1234.5678999, "EUR")
      %Money{amount: -123456790, currency_code: "EUR"}

      iex> Money.to_money(0.0000099999999, "EUR")
      %Money{amount: 1, currency_code: "EUR"}

      iex> Money.to_money(1.0e-5, "EUR")
      %Money{amount: 1, currency_code: "EUR"}

      iex> Money.to_money(-0.00001, "EUR")
      %Money{amount: -1, currency_code: "EUR"}

  ## Examples from integers

      iex> Money.to_money(12345, "EUR")
      %Money{amount: 1234500000, currency_code: "EUR"}

      iex> Money.to_money(-12345, "EUR")
      %Money{amount: -1234500000, currency_code: "EUR"}

  ## Examples with errors

      iex> Money.to_money("123.456!789", "EUR")
      ** (ArgumentError) argument error

      iex> Money.to_money("123!456!789", "EUR")
      ** (ArgumentError) argument error

      iex> Money.to_money("123.456.789", "EUR")
      ** (ArgumentError) argument error

      iex> Money.to_money("SomeUnknownCurrency-123.45")
      ** (ArgumentError) argument error

      iex> Money.to_money("123.45", "SomeUnknownCurrency")
      ** (ArgumentError) argument error

  """
  for %{code: code,
        display: %{code:           display_code,
                   inputPrecision: _display_inputPrecision,
                   name:           _display_name,
                   precision:      _display_precision,
                   shift:          _display_shift,
                   symbol:         display_symbol},
        precision: _precision} <- @currency_config
  do
    if is_binary(display_symbol) do
      def to_money(unquote(display_symbol) <> amount = string) when is_binary(string) do
        to_money(amount, unquote(code))
      end
    end
    if is_binary(display_code) do
      def to_money(unquote(display_code) <> amount = string) when is_binary(string) do
        to_money(amount, unquote(code))
      end
    end
  end
  def to_money(string) when is_binary(string) do
    raise ArgumentError
  end

  def to_money(string_amount, currency_code) when is_binary(string_amount) and is_binary(currency_code) do
    cond do
      String.contains?(string_amount, @decimal_point) ->
        string_amount
        |> :erlang.binary_to_float
        |> __MODULE__.to_money(currency_code)
      true ->
        string_amount
        |> :erlang.binary_to_integer
        |> __MODULE__.to_money(currency_code)
    end
  end

  def to_money(float_amount, currency_code) when is_float(float_amount) and is_binary(currency_code) do
    %{precision: precision} = Map.get(@currency_code_map, currency_code) || raise ArgumentError
    amount =
      float_amount
      |> :erlang.float_to_binary(decimals: precision)
      |> String.replace(@decimal_point, "")
      |> String.to_integer
    %Money{amount: amount, currency_code: currency_code}
  end

  def to_money(integer_amount, currency_code) when is_integer(integer_amount) and is_binary(currency_code) do
    %{precision: precision} = Map.get(@currency_code_map, currency_code) || raise ArgumentError
    %Money{amount: integer_amount * pow10(precision), currency_code: currency_code}
  end

  @doc """
  Converts from Money to strings.

  ## Examples

      iex> Money.to_string(%Money{amount: 12_345_678, currency_code: "GBP"})
      "123.45678"

      iex> Money.to_string(%Money{amount: -12_345_678, currency_code: "PHP"})
      "-123.45678"

      iex> Money.to_string(%Money{amount: 12_345_678, currency_code: "BTC"})
      "0.12345678"

      iex> Money.to_string(%Money{amount: 100_000, currency_code: "EUR"})
      "1.0"

      iex> Money.to_string(%Money{amount: 1_000, currency_code: "EUR"})
      "0.01"

      iex> Money.to_string(%Money{amount: 999, currency_code: "EUR"})
      "0.00999"

      iex> Money.to_string(%Money{amount: 100, currency_code: "EUR"})
      "0.001"

      iex> Money.to_string(%Money{amount: 1, currency_code: "EUR"})
      "0.00001"

      iex> Money.to_string(%Money{amount: 1, currency_code: "BTC"})
      "0.00000001"

      iex> Money.to_string(%Money{amount: 0, currency_code: "BTC"})
      "0.0"

      iex> Money.to_string(%Money{amount: 12345678901234567890123456789012345678901234567890, currency_code: "EUR"})
      "123456789012345678901234567890123456789012345.6789"

  """
  def to_string(%Money{amount: amount, currency_code: currency_code}) do
    %{precision: precision} = Map.get(@currency_code_map, currency_code) || raise ArgumentError
    {integer_string, fractional_string} =
      amount
      |> Integer.to_string
      |> String.split_at(-precision)

    (integer_string
     |> String.pad_leading(1, "0"))
    <>
    @decimal_point
    <>
    (fractional_string
     |> String.pad_leading(precision, "0")
     |> String.trim_trailing("0")
     |> String.pad_leading(1, "0"))
  end

  @doc """
  Converts from Money to floats.

  ## Examples

      iex> Money.to_float(%Money{amount: 12_345_000, currency_code: "EUR"})
      123.45

      iex> Money.to_float(%Money{amount: 12_345_678, currency_code: "EUR"})
      123.45678

      iex> Money.to_float(%Money{amount: -12_345_000, currency_code: "EUR"})
      -123.45

      iex> Money.to_float(%Money{amount: 123_450, currency_code: "EUR"})
      1.2345

      iex> Money.to_float(%Money{amount: 123_456, currency_code: "EUR"})
      1.23456

      iex> Money.to_float(%Money{amount: 123, currency_code: "EUR"})
      0.00123

      iex> Money.to_float(%Money{amount: 1, currency_code: "EUR"})
      1.0e-5

      iex> Money.to_float(%Money{amount: 0, currency_code: "EUR"})
      0.0

      iex> Money.to_float(%Money{amount: 12345678901234567890123456789012345678901234567890, currency_code: "EUR"})
      1.2345678901234567e44

  """
  def to_float(%Money{} = money) do
    money
    |> __MODULE__.to_string
    |> :erlang.binary_to_float
  end

  @cents_precision 2

  @doc """
  Converts amounts of money from integer cents with currency symbols to Money.

  ## Examples

      iex> Money.from_cents(12_345, "EUR")
      %Money{amount: 12345000, currency_code: "EUR"}

      iex> Money.from_cents("12345", "EUR")
      %Money{amount: 12345000, currency_code: "EUR"}

  """
  def from_cents(integer_amount, currency_code) when is_integer(integer_amount) and is_binary(currency_code) do
    %{precision: precision} = Map.get(@currency_code_map, currency_code) || raise ArgumentError
    %Money{amount: integer_amount * pow10(precision - @cents_precision), currency_code: currency_code}
  end

  def from_cents(string_amount, currency_code) when is_binary(string_amount) and is_binary(currency_code) do
    string_amount
    |> :erlang.binary_to_integer
    |> __MODULE__.from_cents(currency_code)
  end

  @doc """
  Converts from Money to integer cents.

  ## Examples

      iex> Money.to_cents(%Money{amount: 12_345_000, currency_code: "EUR"})
      12_345

      iex> Money.to_cents(%Money{amount: 12_345_678, currency_code: "EUR"})
      12_346

  """
  def to_cents(%Money{amount: amount, currency_code: currency_code}) do
    %{precision: precision} = Map.get(@currency_code_map, currency_code) || raise ArgumentError
    round(amount / pow10(precision - @cents_precision))
  end

  @pow10_max 104
  Enum.reduce 0..@pow10_max, 1, fn int, acc ->
    defp pow10(unquote(int)), do: unquote(acc)
    acc * 10
  end
  defp pow10(int) when int > @pow10_max do
    pow10(@pow10_max) * pow10(int - @pow10_max)
  end
end
