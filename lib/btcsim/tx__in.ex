defmodule Bitcoin.Tx_In do
  @moduledoc false
  @derive [Poison.Encoder]
  defstruct [:pout,:n, :sig, :pk]
  def new(prev_out,n,sig,pk) do
    %__MODULE__{
      pout: prev_out,
      n: n,
      sig: sig,
      pk: pk
    }
  end

end
