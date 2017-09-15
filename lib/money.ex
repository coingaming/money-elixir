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

  @decimal_point "."

  @doc """

  Converts from strings with the currency symbols and amount to Money.

  ## Examples

      iex> Money.from_string("EUR123.456789")
      %Money{amount: 12345678, currency_code: "EUR"}

      iex> Money.from_string("$123.45")
      %Money{amount: 12345000, currency_code: "USD"}

      iex> Money.from_string("$123")
      %Money{amount: 12300000, currency_code: "USD"}

      iex> Money.from_string("$123.")
      %Money{amount: 12300000, currency_code: "USD"}

      iex> Money.from_string("$.45")
      %Money{amount: 45000, currency_code: "USD"}

      iex> Money.from_string("$-123.45")
      %Money{amount: -12345000, currency_code: "USD"}

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
      def from_string(unquote(display_symbol) <> amount = string) when is_binary(string) do
        from_string(amount, unquote(code))
      end
    end
    if is_binary(display_code) do
      def from_string(unquote(display_code) <> amount = string) when is_binary(string) do
        from_string(amount, unquote(code))
      end
    end
  end

  def from_string(amount_string, currency_code) when is_binary(amount_string) and is_binary(currency_code) do
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
    end
  end

  @doc """

  Converts from Money to strings with the currency symbols and amount.

  ## Examples

      iex> Money.to_string(%Money{amount: 12_345_678, currency_code: "GBP"})
      "123.45"

      iex> Money.to_string(%Money{amount: -12_345_678, currency_code: "PHP"})
      "-123.45"

      iex> Money.to_string(%Money{amount: 12_345_678, currency_code: "BTC"})
      "0.1234"

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
           |> String.slice(0..display_precision-1)
    do
      div_string <> @decimal_point <> rem_string
    else
      error ->
        Logger.error "error: #{inspect error}, amount: #{inspect amount}, code: #{inspect currency_code}"
    end
  end

  @doc """

  Converts from float amounts with the currency symbols to Money.

  ## Examples

      iex> Money.from_float(123.45, "EUR")
      %Money{amount: 12345000, currency_code: "EUR"}

      iex> Money.from_float(-1234.5678999, "EUR")
      %Money{amount: -123456789, currency_code: "EUR"}

  """
  def from_float(float, currency_code) when is_float(float) and is_binary(currency_code) do
    float
    |> Float.to_string
    |> __MODULE__.from_string(currency_code)
  end

  @doc """

  Converts from Money to float amounts with the currency symbols.

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
