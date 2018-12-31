defmodule Bitcoin.Block do

  alias Bitcoin.Crypto

  @moduledoc false
  defstruct [:version, :pblock, :mroot, :time, :nbits, :nonce, :tcount, :txns, :hash]

  @doc "Genesis block of the blockchain"
  def genblock(trans) do
    %__MODULE__{
      version: 0,
      pblock: "0",
      mroot: nil,
      time: DateTime.utc_now
            |> DateTime.to_unix(),
      nbits: 3,
      nonce: 0,
      tcount: length(trans),
      txns: trans,
      hash: nil
    }
  end

  def new(prev, trans) do
    %__MODULE__{
      version: 0,
      pblock: prev,
      mroot: nil,
      time: DateTime.utc_now
            |> DateTime.to_unix(),
      nbits: 4,
      nonce: 0,
      tcount: length(trans),
      txns: trans,
      hash: nil
    }
  end

  def addtrans(block, trans) do
    block = Map.put(block, :txns, [trans] ++ block.txns)
    Map.put(block, :tcount, length(block.txns))
  end

  def calchash(block) do
    bhash = calchash(block.version, block.pblock, block.mroot, block.time, block.nbits, block.nonce , block.txns)
    %{block | hash: bhash}
  end

  def calchash(version, pblock, mroot, time, nbits, nonce,txns) do
    txns_text = Poison.encode!(txns)
    serialize = "#{version}#{pblock}#{mroot}#{time}#{nbits}#{nonce}#{txns_text}}"
    Crypto.dhash(serialize)
  end

  def checkhash(block) do
    target = String.duplicate("0", block.nbits) <> String.duplicate("F", 64 - block.nbits)
    check = block.hash < target
    if check do
      #IO.inspect(target)
     # IO.inspect(block.hash)
     # IO.inspect(check)
    end
    check
  end

  def mine(block) do
    block = calchash(block)
    #IO.inspect("Mining Nonce = #{block.nonce}")
    cond do
      checkhash(block) ->
        IO.inspect("Genblock Mining completed")
        block
      true ->
        %{block | nonce: block.nonce + 1}
        |> mine
    end
  end

end
