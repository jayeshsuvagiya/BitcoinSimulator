defmodule Bitcoin.Tx_Out do
  @moduledoc false
  defstruct [:value,:rpkh]

  def new(value,rpkh) do
    %__MODULE__{
      value: value,
      rpkh: rpkh,
    }
  end

end
