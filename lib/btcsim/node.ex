defmodule Bitcoin.Node do
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
    miner = Bitcoin.NetworkSupervisor.add_miner()
    Process.send_after(self(),:check_pool,10000)
    {
      :reply,
      :ok,
      {sk, pk, pkh, [genblock], {nil, []}, %{}, %{}, n_utxo, name, miner}
    }
  end

  def handle_info(:check_pool, {sk, pk, pkh, blockchain, fork, orphan, tranpool, utxo, name, miner}) do
    ismining = GenServer.call(miner, :get_status)
   # IO.inspect("#{name} do_mine_a #{ismining} #{Enum.count(tranpool)}")
    if(!ismining && Enum.count(tranpool) > 0) do
      t_in = Bitcoin.Tx_In.new(0, -1, nil, nil)
      tout = Bitcoin.Tx_Out.new(25, pkh)
      reward_tran = Bitcoin.Transaction.new([t_in], [tout])
      reward_tran = Bitcoin.Transaction.calchash(reward_tran)
      trans = [reward_tran | Map.values(tranpool)]
      block = Bitcoin.Block.new(List.first(blockchain).hash, trans)
      GenServer.call(miner, {:start_mine, block, name})
    end
    Process.send_after(self(),:check_pool,20000)
     {:noreply,{sk, pk, pkh, blockchain, fork, orphan, tranpool, utxo, name, miner}}
  end

  def handle_call(:get_address, _from, {sk, pk, pkh, blockchain, fork, orphan, tranpool, utxo, name, miner}) do
    {:reply, {name,pkh}, {sk, pk, pkh, blockchain, fork, orphan, tranpool, utxo, name, miner}}
  end

  def handle_cast(:test, {sk, pk, pkh, blockchain, fork, orphan, tranpool, utxo, name, miner}) do
    {:noreply, {sk, pk, pkh, blockchain, fork, orphan, tranpool, utxo, name, miner}}
  end

  def handle_cast({:rec_trans, trans}, {sk, pk, pkh, blockchain, fork, orphan, tranpool, utxo, name, miner}) do
   # IO.inspect("Transaction Recieved #{name}}")
    tranpool = if verify(trans, blockchain, tranpool, utxo) do
      tp = Map.put(tranpool, trans.hash, trans)
      ismining = GenServer.call(miner, :get_status)
    #  IO.inspect("#{name} do_mine_t #{ismining} #{Enum.count(tp)}")

      #IO.inspect(miner)

      if(!ismining && Enum.count(tp) > 5) do

        t_in = Bitcoin.Tx_In.new(0, -1, nil, nil)
        tout = Bitcoin.Tx_Out.new(25, pkh)
        reward_tran = Bitcoin.Transaction.new([t_in], [tout])
        reward_tran = Bitcoin.Transaction.calchash(reward_tran)
        trans = [reward_tran | Map.values(tp)]
        block = Bitcoin.Block.new(List.first(blockchain).hash, trans)
        GenServer.call(miner, {:start_mine, block, name})
        #block = Bitcoin.Block.mine(block)
        #GenServer.cast(Bitcoin.BitcoinSimulator, {:broad_block, block})
        tp
      else
        tp
      end
    else
    #  IO.inspect("#{name} verfied fail #{trans.hash}")
      tranpool
    end
    {:noreply, {sk, pk, pkh, blockchain, fork, orphan, tranpool, utxo, name, miner}}
  end

  def handle_cast({:rec_block, block}, {sk, pk, pkh, blockchain, fork, orphan, tranpool, utxo, name, miner}) do
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
        {:add_main, _x} -> {:ok, myblock} = GenServer.call(miner, :stop)
                           # IO.inspect(" Trans 1 = #{name}")
                           # IO.inspect(Map.keys(tranpool))
                           [h | t] = myblock.txns
                           tp = Enum.map(t, fn trans -> {trans.hash, trans} end)
                                |> Map.new
                                |> Map.merge(tranpool)
                           Process.sleep(1000)
                           # IO.inspect(" Trans 2 = #{name}")
                           #  IO.inspect(Map.keys(tp))
                           bkc = [block | blockchain]
                           Process.sleep(1000)
                           tp = remove_trans(tp, block.txns)
                           #  IO.inspect(" Trans 3 = #{name}")
                           #  IO.inspect(Map.keys(tp))
                           if Enum.count(tp) > 5 do
                          #   IO.inspect("#{name} do_mine_b")
                             t_in = Bitcoin.Tx_In.new(0, -1, nil, nil)
                             tout = Bitcoin.Tx_Out.new(25, pkh)
                             reward_tran = Bitcoin.Transaction.new([t_in], [tout])
                             reward_tran = Bitcoin.Transaction.calchash(reward_tran)
                             trans = [reward_tran | Map.values(tp)]
                             bk = Bitcoin.Block.new(List.first(bkc).hash, trans)
                             GenServer.call(miner, {:start_mine, bk, name})
                           end

                           n_utxo = remove_utxo(utxo, block.txns)
                           n_utxo = addutxo(n_utxo, block.txns)
                           {sk, pk, pkh, bkc, fork, orphan, tp, n_utxo, name, miner}
        #add to fork and check height replace main else do nothing
        {:add_fork, _x} -> {a, f} = fork
                           newf = [block | fork]
                           #todo switch longest chain
                           {sk, pk, pkh, blockchain, newf, orphan, tranpool, utxo, name, miner}
        #create a fork with a height pointer
        {:create_fork, a} -> fork = {length(blockchain) - a, [block]}
                             {sk, pk, pkh, blockchain, fork, orphan, tranpool, utxo, name, miner}
        # add to orphan do nothing
        {:add_orphan, "Add to orphan"} -> orphan = Map.put(orphan, block.hash, block)
                                          {sk, pk, pkh, blockchain, fork, orphan, tranpool, utxo, name, miner}
        # reject block and continue
        {:reject, _x} -> {sk, pk, pkh, blockchain, fork, orphan, tranpool, utxo, name, miner}
      end
    {:noreply, z}
  end


  def handle_cast(
        {:block_mined, block},
        status
      ) do
    GenServer.call(BitcoinSimulator, {:broad_block, block})
    {:noreply, status}
  end

  def handle_cast(:check_bal, {sk, pk, pkh, blockchain, fork, orphan, tranpool, utxo, name, miner}) do
    sum = check_bal(utxo, pkh)
    IO.inspect("BALANCE OF #{pkh} #{name} = #{sum}")
    # IO.inspect(utxo)
    {:noreply, {sk, pk, pkh, blockchain, fork, orphan, tranpool, utxo, name, miner}}
  end

  def handle_cast(
        {:perform_trans, rpkh, amount, sender_name},
        {sk, pk, pkh, blockchain, fork, orphan, tranpool, utxo, name, miner}
      ) do
    tran_fee = 0
    trans = case find_in_utxo(utxo, amount + tran_fee, pkh) do
      {:ok, total, utxos} ->
        IO.inspect("From #{name} to #{sender_name} amount = #{amount}")
        input_trans = Enum.map(
          utxos,
          fn {trans, n} ->
            out = Enum.fetch!(trans.tx_out, n)
            data = "#{trans.hash}#{n}#{out.rpkh}#{rpkh}#{amount}}"
            sign = Bitcoin.Crypto.sign(data, sk)
            Bitcoin.Tx_In.new(trans.hash, n, sign, pk)
          end
        )
        #if extra amount send to self add out to self  # add transaction fee
        tout = Bitcoin.Tx_Out.new(amount, rpkh)
        output_trans = [tout]
        output_trans = if total > amount + tran_fee do
          sout = Bitcoin.Tx_Out.new(total - amount - tran_fee, pkh)
          [sout | output_trans]
        else
          output_trans
        end
        trans = Bitcoin.Transaction.new(input_trans, output_trans)
        trans = Bitcoin.Transaction.calchash(trans)
        GenServer.cast(BitcoinSimulator, {:broad_trans, trans})
        BtcsimWeb.BtcChannel.broadcast_tran({name,sender_name,amount})
        trans
      _ ->
        #IO.puts("#{name} Cannot send money as funds not enough.")
        nil
    end
    tranpool = if trans != nil do
      #Map.put(tranpool, trans.hash, trans) broadcast to self will handle ir
      tranpool
    else
      tranpool
    end
    {:noreply, {sk, pk, pkh, blockchain, fork, orphan, tranpool, utxo, name, miner}}
  end

  def find_in_utxo(utxo, amount, pkh) do
    sorted = Enum.filter(utxo, fn {{id, n}, trans} -> Enum.fetch!(trans.tx_out, n).rpkh == pkh end)
    sorted = sorted
             |> Enum.sort(
                  fn {{id, n}, trans}, {{id2, n2}, trans2} ->
                    Enum.fetch!(trans.tx_out, n) <= Enum.fetch!(trans2.tx_out, n2)
                  end
                )
    utrxos = Enum.reduce_while(
      sorted,
      {0, []},
      fn {{id, n}, trans}, {value, x} ->
        value = value + Enum.fetch!(trans.tx_out, n).value;
        if value < amount, do: {:cont, {value, [{trans, n}] ++ x}}, else: {:halt, {value, [{trans, n}] ++ x}}
      end
    )
    #IO.inspect(utrxos);
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
   # IO.inspect("check 1 - #{check} #{Enum.count(tranpool)}")
    check = Enum.find(tranpool, fn {k, v} -> k == trans.hash end)
  #  IO.inspect("check 2 - #{check}")
    check = Enum.find(utxo, fn {{t, n}, _x} -> t == trans.hash end)
  #  IO.inspect("check 3 - #{check}")
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
