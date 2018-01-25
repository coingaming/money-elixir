defmodule Money.Constants do
  @raw_config Application.app_dir(:ih_money, "priv/currency-config/config.json")
                   |> File.read!
                   |> Poison.decode!(keys: :atoms)

  # In currency_config all keys are atoms, while we need strings. Next block of code transforms currency codes into strings
  @currency_config (
    Enum.reduce(@raw_config, %{}, fn {currency_code, specs = %{units: units,
                                                                    code: code,
                                                                    precision: precision}},
                                                                    acc when is_atom(currency_code) and
                                                                             is_binary(code) and
                                                                             is_integer(precision) and
                                                                             is_map(units) -> 
      Map.put(acc, Atom.to_string(currency_code), %{specs | units: 
        Enum.reduce(units, %{}, fn {currency_unit, %{code: unit_code,
                                                     name: unit_name,
                                                     displayPrecision: displayPrecision,
                                                     inputPrecision: inputPrecision,
                                                     shift: shift,
                                                     symbol: symbol} = unit_specs},
                                                     units_acc when is_atom(currency_unit) and
                                                                    is_binary(unit_code) and
                                                                    is_binary(unit_name) and
                                                                    is_integer(displayPrecision) and
                                                                    is_integer(inputPrecision) and
                                                                    is_integer(shift) and
                                                                    is_binary(symbol) and
                                                                    ((precision - shift) >= 0) 
                                                                    -> 
          Map.put(units_acc, Atom.to_string(currency_unit), unit_specs) end)})
  end))

  @doc """
  Returns raw currencies config
  """
  def raw_config, do: @raw_config

  @doc """
  Returns preprocessed currencies config
  """
  def currency_config, do: @currency_config
end
