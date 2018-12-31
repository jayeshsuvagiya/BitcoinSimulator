defmodule Bitcoin.Transaction do
  @moduledoc false
  defstruct [:version, :tx_in_count, :tx_out_count, :tx_in, :tx_out, :locktime, :hash]

  def new(input, out) do
    %__MODULE__{
      version: 0,
      tx_in_count: length(input),
      tx_out_count: length(input),
      tx_in: input,
      tx_out: out,
      locktime: 0,
      hash: nil
    }
  end

  def calchash(trans) do
    thash=calchash(trans.version,trans.tx_in_count,trans.tx_out_count,trans.tx_in,trans.tx_out,trans.locktime)
    %{trans | hash: thash}
  end

  def calchash(version,tx_in_count,tx_out_count,tx_in,tx_out,locktime) do
    in_txt = Enum.map(tx_in,fn x -> Poison.encode!(x) end)
    out_txt = Enum.map(tx_out,fn x -> "#{x.value}#{x.rpkh}" end)
    #IO.inspect(out_txt)
    #IO.inspect(in_txt)
    serialize = "#{version}#{tx_in_count}#{tx_out_count}#{in_txt}#{out_txt}#{locktime}"
    Bitcoin.Crypto.dhash(serialize)
  end


  def addinput(trans,input) do
    trans = %{trans | tx_in: trans.tx_in ++ [input]}
    trans = %{trans | tx_in_count: trans.tx_in_count+1}
    calchash(trans)
  end

  def addout(trans,output) do
    trans = %{trans | tx_out: trans.tx_out ++ [output]}
    trans = %{trans | tx_out_count: trans.tx_out_count+1}
    calchash(trans)
  end
end
