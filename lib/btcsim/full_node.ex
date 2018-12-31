defmodule Bitcoin.FullNode do
  use GenServer, restart: :temporary
  require Logger

  @moduledoc false
  @max 21000000

  def start_link({genblock, identifier}) do
    GenServer.start_link(__MODULE__, {genblock, identifier}, name: {:global, identifier})
  end

  def init({genblock, name}) do
    #IO.inspect(genblock)
    # Process.send_after(self(), :do_one_itr, 0)
    {
      :ok,
      {genblock, name}
    }
  end

  def handle_call(:kick_off, _from, {genblock, name}) do
    sk = Bitcoin.Crypto.generate()
    pk = Bitcoin.Crypto.to_public_key(sk)
    pkh = Bitcoin.Crypto.to_public_hash(pk)
    n_utxo = Enum.map(
               genblock.txns,
               fn trans ->
                 Enum.with_index(trans.tx_out)
                 |> Enum.map(fn {tout, i} -> {{trans.hash, i}, trans} end)
               end
             )
             |> Enum.concat
             |> Map.new

    {
      :reply,
      :ok,
      {sk, pk, pkh, [genblock], {nil, []}, %{}, %{}, n_utxo, name, 0, 0, 25}
    }
  end




  def handle_cast({:rec_trans, trans}, {sk, pk, pkh, blockchain, fork, orphan, tranpool, utxo, name, notn, aot, aob}) do
    #IO.inspect("Transaction Recieved #{name}}")
    tranpool = if verify(trans, blockchain, tranpool, utxo) do
      Map.put(tranpool, trans.hash, trans)
    else
      tranpool
    end
    {:noreply, {sk, pk, pkh, blockchain, fork, orphan, tranpool, utxo, name, notn, aot, aob}}
  end

  def handle_cast({:rec_block, block}, {sk, pk, pkh, blockchain, fork, orphan, tranpool, utxo, name, notn, aot, aob}) do
    {m, side_branch} = fork

    #IO.inspect("Recieve block - #{name} - size main - #{length(blockchain)} - hash - block #{block.hash}")
    #if m != nil do
    #IO.inspect("Recieve block -- size fork - #{length(m)}") end
    #IO.inspect(block.hash)
    result = verify_block(block, blockchain, fork, orphan)
    #IO.inspect(result)
    z =
      case result do
        #todo add to main branch start mine or add to fork or orphan
        #add to main and start mine on top
        {:add_main, _x} ->
          bkc = [block | blockchain]

          tp = remove_trans(tranpool, block.txns)

          [h | t] = block.txns
          #IO.inspect(Enum.count(t))
          txn_block = Enum.count(t)
          notn = notn + txn_block
          amount_of_tran = Enum.map(t, fn tx -> Enum.reduce(tx.tx_out, 0, fn tout, acc -> tout.value + acc end) end)
                           |> Enum.sum()
          aot = aot + amount_of_tran

          aob = aob + 25
                height_bc = length(bkc);
          BtcsimWeb.BtcChannel.broadcast_notx(%{notx: notn})
          BtcsimWeb.BtcChannel.broadcast_aoblck(%{amt_blck: amount_of_tran,y: height_bc})
          BtcsimWeb.BtcChannel.broadcast_txblck(%{tx_blck: txn_block,x: height_bc})
          BtcsimWeb.BtcChannel.broadcast_aotx(%{aotx: aot})
          BtcsimWeb.BtcChannel.broadcast_aobtc(%{aobtc: aob})

          n_utxo = remove_utxo(utxo, block.txns)
          n_utxo = addutxo(n_utxo, block.txns)
          {sk, pk, pkh, bkc, fork, orphan, tp, n_utxo, name, notn, aot, aob}
        #add to fork and check height replace main else do nothing
        {:add_fork, _x} -> {a, f} = fork
                           newf = [block | fork]
                           #todo switch longest chain
                           {sk, pk, pkh, blockchain, newf, orphan, tranpool, utxo, name, notn, aot, aob}
        #create a fork with a height pointer
        {:create_fork, a} -> fork = {length(blockchain) - a, [block]}
                             {sk, pk, pkh, blockchain, fork, orphan, tranpool, utxo, name, notn, aot, aob}
        # add to orphan do nothing
        {:add_orphan, "Add to orphan"} -> orphan = Map.put(orphan, block.hash, block)
                                          {sk, pk, pkh, blockchain, fork, orphan, tranpool, utxo, name, notn, aot, aob}
        # reject block and continue
        {:reject, _x} -> {sk, pk, pkh, blockchain, fork, orphan, tranpool, utxo, name, notn, aot, aob}
      end
    {:noreply, z}
  end


  def find_in_utxo(utxo, amount, pkh) do
    sorted = Enum.filter(utxo, fn {{id, n}, trans} -> trans.tx_out[n].rpkh == pkh end)
             |> Enum.sort(fn {{id, n}, trans}, {{id2, n2}, trans2} -> trans.tx_out[n] <= trans2.tx_out[n2] end)
    utrxos = Enum.reduce_while(
      sorted,
      {0, []},
      fn {{id, n}, trans}, {value, x} ->
        value = value + trans.tx_out[n].value;
        if value < amount, do: {:cont, {value, [{trans, n}] ++ x}}, else: {:halt, {value, [{trans, n}] ++ x}}
      end
    )
    IO.inspect(utrxos);
    case utrxos do
      {0, []} ->
        {:error, "No Transaction Balance"}
      {a, tlist} ->
        if a >= amount do
          {:ok, a, tlist}
        else
          {:error, "Insufficient Funds"}
        end
      _ -> {:error, "Insufficient Funds"}
    end
  end



  def check_bal(utxo, pkh) do
    sum = Enum.filter(
            utxo,
            fn {{id, n}, trans} -> a = Enum.fetch!(trans.tx_out, n)
                                   a.rpkh == pkh
            end
          )
          |> Enum.reduce(
               0,
               fn {{id, n}, trans}, bal ->
                 bal = bal + Enum.fetch!(trans.tx_out, n).value;
               end
             )
    sum
  end

  def verify(trans, blockchain, tranpool, utxo) do
    check = nil
    check = Enum.find(blockchain, fn block -> Enum.find(block.txns, fn t -> t.hash == trans.hash end) end)
    check = Enum.find(tranpool, fn {k, v} -> k == trans.hash end)
    check = Enum.find(utxo, fn {{t, n}, _x} -> t == trans.hash end)
    #to do check every input for output
    if check == nil do
      #todo verify signature
      true
    else
      false
    end
  end

  def verify_block(block, blockchain, {n, fork}, orphan) do
    check = nil
    check = Enum.find(blockchain, fn b -> b.hash == block.hash  end)
    check = Enum.find(fork, fn b -> b.hash == block.hash  end)
    #to do check orphan
    if (check == nil) do
      cond do
        block.pblock == List.first(blockchain).hash -> {:add_main, "Add to main blockchain"}
        length(fork) > 0 && block.pblock == List.first(fork).hash -> {:add_fork, "Add to fork blockchain"}
        true -> a = Enum.find_index(blockchain, fn b -> b.hash == block.pblock  end)
                b = Enum.find_index(fork, fn b -> b.hash == block.pblock  end)
                cond do
                  a < 5 -> {:create_fork, a}
                  a == nil && b == nil -> {:add_orphan, "Add to orphan"}
                  true -> {:reject, "Reject Block"}
                end
      end
    else
      {:reject, "Reject Block"}
    end
  end


  def addutxo(utxo, trans) do
    Enum.map(
      trans,
      fn t ->
        Enum.with_index(t.tx_out)
        |> Enum.map(fn {z, i} -> {{t.hash, i}, t} end)
      end
    )
    |> Enum.concat
    |> Map.new
    |> Map.merge(utxo)
  end

  def remove_utxo(utxo, trans) do
    keys = Enum.map(
      trans,
      fn t ->
        t.tx_in
        |> Enum.map(fn tin -> {tin.pout, tin.n} end)
      end
    )
    Map.drop(utxo, keys)
  end

  def remove_trans(transpool, txns) do
    keys = Enum.map(
      txns,
      fn t ->
        t.hash
      end
    )
    Map.drop(transpool, keys)
  end

end
