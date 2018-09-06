defmodule Money.Int do
  @raw_config Money.Constants.raw_config()
  @currency_config Money.Constants.currency_config()

  @raw_config
  |> Enum.flat_map(fn({_, %{units: units = %{}}}) -> Map.keys(units) end)
  |> Enum.uniq
  |> Enum.each(fn(unit) ->

    from_function_name = "from_#{unit}" |> String.to_atom
    to_function_name = "to_#{unit}" |> String.to_atom
    unit_string = unit |> Atom.to_string

    @doc """
    Converts amounts of money from integer cents with currency symbols to Money.

    ## Examples

        iex> Money.Int.from_cent(12_345, "EUR")
        %Money{amount: 12345000, currency_code: "EUR", currency_unit: "cent"}

        iex> Money.Int.from_cent("12345", "EUR")
        %Money{amount: 12345000, currency_code: "EUR", currency_unit: "cent"}

        iex> Money.Int.from_cent("12345", "Euro")
        ** (ArgumentError) Unsupported currency 'Euro'

    """
    @spec unquote(from_function_name)(String.t | pos_integer, String.t) :: %Money{}
    def unquote(from_function_name)(integer_amount, currency_code) when is_integer(integer_amount) and is_binary(currency_code) do
      %{precision: precision, units: %{unquote(unit_string) => %{shift: shift}}} =
        Map.get(@currency_config, currency_code) || raise ArgumentError, "Unsupported currency '#{currency_code}'"
      %Money{amount: integer_amount * Money.pow10(precision - shift), currency_code: currency_code, currency_unit: unquote(unit_string)}
    end
    def unquote(from_function_name)(string_amount, currency_code) when is_binary(string_amount) and is_binary(currency_code) do
      string_amount
      |> :erlang.binary_to_integer
      |> unquote(from_function_name)(currency_code)
    end

    @doc """
    Converts from Money to integer cents.

    ## Examples

        iex> Money.Int.to_cent(%Money{amount: 12_345_000, currency_code: "EUR", currency_unit: "cent"})
        12_345

        iex> Money.Int.to_cent(%Money{amount: 12_345_678, currency_code: "EUR", currency_unit: "cent"})
        12_345

        iex> Money.Int.to_cent(%Money{amount: 12_345_678, currency_code: "Euro", currency_unit: "cent"})
        ** (ArgumentError) Unsupported currency 'Euro'

    """
    @spec unquote(to_function_name)(%Money{}) :: pos_integer
    def unquote(to_function_name)(%Money{amount: amount, currency_code: currency_code}) do
      %{precision: precision, units: %{unquote(unit_string) => %{shift: shift}}} =
        Map.get(@currency_config, currency_code) || raise ArgumentError, "Unsupported currency '#{currency_code}'"
      trunc(amount / Money.pow10(precision - shift))
    end

  end)
end
