defmodule Money.Constants do
  @raw_config Application.app_dir(:ih_money, "priv/currency-config/config.json")
                   |> File.read!
                   |> Poison.decode!(keys: :atoms)
  @additional_currencies %{
    mBTC: %{
      code: "mBTC",
      precision: 5,
      units: %{
        mBTC: %{
          code: "mBTC",
          symbol: "m₿",
          name: "Milli-bitcoin",
          shift: 0,
          displayPrecision: 0,
          inputPrecision: 4
        }
      }
    },
    uBTC: %{
      code: "uBTC",
      precision: 5,
      units: %{
        uBTC: %{
          code: "uBTC",
          symbol: "μ₿",
          name: "Bits",
          shift: 0,
          displayPrecision: 0,
          inputPrecision: 4
        }
      }
    },
    mETH: %{
      code: "mETH",
      precision: 5,
      units: %{
        mETH: %{
          code: "mETH",
          symbol: "mETH",
          name: "Milliether",
          shift: 0,
          displayPrecision: 0,
          inputPrecision: 4
        }
      }
    },
    uETH: %{
      code: "uETH",
      precision: 5,
      units: %{
        uETH: %{
          code: "uETH",
          symbol: "μETH",
          name: "Microether",
          shift: 0,
          displayPrecision: 0,
          inputPrecision: 4
        }
      }
    },
    mLTC: %{
      code: "mLTC",
      precision: 5,
      units: %{
        mLTC: %{
          code: "mLTC",
          symbol: "mŁ",
          name: "milli-Litecoin",
          shift: 0,
          displayPrecision: 0,
          inputPrecision: 4
        }
      }
    },
    uLTC: %{
      code: "uLTC",
      precision: 5,
      units: %{
        uLTC: %{
          code: "uLTC",
          symbol: "μŁ",
          name: "micro-Litecoin",
          shift: 0,
          displayPrecision: 0,
          inputPrecision: 4
        }
      }
    },
  }
  # In currency_config all keys are atoms, while we need strings. Next block of code transforms currency codes into strings
  @currency_config (
    Enum.reduce(Map.merge(@raw_config, @additional_currencies), %{}, fn {currency_code, specs = %{units: units,
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
  def raw_config, do: Map.merge(@raw_config, @additional_currencies)

  @doc """
  Returns preprocessed currencies config
  """
  def currency_config, do: @currency_config

  @doc """
  Returns list of addotional currencies(the ones which are sub_units_of other currencies)
  """
  def additional_currencies, do: @additional_currencies
end
