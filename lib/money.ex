defmodule Money do
  require Logger

  @moduledoc """

  Money amount converter.

  Converts money amounts with different currencies.

  """

  defstruct [:amount, :currency_code]

  @currency_config Application.app_dir(:money, "priv/currency-config/config.json")
                   |> File.read!
                   |> Poison.decode!(keys: :atoms)

  @currency_code_map Enum.reduce(@currency_config, %{}, fn(%{code: code} = currency, acc) ->
    Map.put(acc, code, currency)
  end)

  @max_decimals Enum.reduce(@currency_config, 0, fn(%{precision: precision}, acc) -> max(precision, acc) end)

  @decimal_point "."

  @doc """
  Converts amounts of money from strings, floats or integers with currency symbols to Money.

  ## Examples from strings with currency symbols inside

      iex> Money.to_money("$123.45")
      %Money{amount: 12345000, currency_code: "USD"}

      iex> Money.to_money("$123")
      %Money{amount: 12300000, currency_code: "USD"}

      iex> Money.to_money("$123.")
      %Money{amount: 12300000, currency_code: "USD"}

      iex> Money.to_money("$.45")
      %Money{amount: 45000, currency_code: "USD"}

      iex> Money.to_money("$-123.45")
      %Money{amount: -12345000, currency_code: "USD"}

  ## Examples from strings with currency symbols as a separate argument

      iex> Money.to_money("123.456789", "EUR")
      %Money{amount: 12345678, currency_code: "EUR"}

  ## Examples from floats

      iex> Money.to_money(123.45, "EUR")
      %Money{amount: 12345000, currency_code: "EUR"}

      iex> Money.to_money(-1234.5678999, "EUR")
      %Money{amount: -123456789, currency_code: "EUR"}

      iex> Money.to_money(1.0e-5, "EUR")
      %Money{amount: 1, currency_code: "EUR"}

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

  def to_money(amount_string, currency_code) when is_binary(amount_string) and is_binary(currency_code) do
    [integer_string, fractional_string] =
      amount_string
      |> String.split(@decimal_point)
      |> case do
           [integer_string] ->
             [integer_string, "0"]
           [integer_string, ""] ->
             [integer_string, "0"]
           ["", fractional_string] ->
             ["0", fractional_string]
           [integer_string, fractional_string] ->
             [integer_string, fractional_string]
           _ ->
             raise ArgumentError
         end
    with %{precision: precision} <-
           Map.get(@currency_code_map, currency_code),
         {integer,    ""} <-
           integer_string
           |> Integer.parse,
         {fractional, ""} <-
           fractional_string
           |> String.slice(0..precision-1)
           |> String.pad_trailing(precision, "0")
           |> Integer.parse,
         pow10 <-
           pow10(precision),
         amount <-
           (cond do
             integer < 0 -> integer * pow10 - fractional
             true        -> integer * pow10 + fractional
           end)
    do
      %Money{amount: amount, currency_code: currency_code}
    else
      error ->
        Logger.error "error: #{inspect error}, amount: #{inspect amount_string}, code: #{inspect currency_code}"
        raise ArgumentError
    end
  end

  def to_money(float, currency_code) when is_float(float) and is_binary(currency_code) do
    float
    |> :erlang.float_to_binary(decimals: @max_decimals)
    |> __MODULE__.to_money(currency_code)
  end

  def to_money(integer, currency_code) when is_integer(integer) and is_binary(currency_code) do
    integer
    |> Integer.to_string
    |> __MODULE__.to_money(currency_code)
  end

  @doc """
  Converts from Money to strings.

  ## Examples

      iex> Money.to_string(%Money{amount: 12_345_678, currency_code: "GBP"})
      "123.45"

      iex> Money.to_string(%Money{amount: -12_345_678, currency_code: "PHP"})
      "-123.45"

      iex> Money.to_string(%Money{amount: 12_345_678, currency_code: "BTC"})
      "0.1234"

      iex> Money.to_string(%Money{amount: 100, currency_code: "EUR"})
      "0.00"

      iex> Money.to_string(%Money{amount: 1_000, currency_code: "EUR"})
      "0.01"

  """
  def to_string(%Money{amount: amount, currency_code: currency_code}) do
    with %{display: %{precision: display_precision}, precision: precision} <-
           Map.get(@currency_code_map, currency_code),
         pow10 <-
           pow10(precision),
         div <-
           div(amount, pow10),
         rem <-
           abs(rem(amount, pow10)),
         div_string <-
           div
           |> Integer.to_string,
         rem_string <-
           rem
           |> Integer.to_string
           |> String.pad_leading(precision, "0")
           |> String.slice(0..display_precision-1)
    do
      div_string <> @decimal_point <> rem_string
    else
      error ->
        Logger.error "error: #{inspect error}, amount: #{inspect amount}, code: #{inspect currency_code}"
        raise ArgumentError
    end
  end

  @doc """
  Converts from Money to floats.

  ## Examples

      iex> Money.to_float(%Money{amount: 12_345_000, currency_code: "EUR"})
      123.45

      iex> Money.to_float(%Money{amount: -12_345_000, currency_code: "EUR"})
      -123.45

  """
  def to_float(%Money{} = money) do
    money
    |> __MODULE__.to_string
    |> String.to_float
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
