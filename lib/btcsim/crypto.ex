defmodule Bitcoin.Crypto do
  @moduledoc false

  @max :binary.decode_unsigned(<<0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFE, 0xBA, 0xAE, 0xDC, 0xE6, 0xAF, 0x48, 0xA0, 0x3B, 0xBF, 0xD2, 0x5E, 0x8C, 0xD0, 0x36, 0x41, 0x41>>)

  def dhash(data) do
  data |> hash(:sha256)|> hash(:sha256) |> Base.encode16()
  end

  def sign(data,sk) do
    :crypto.sign(:ecdsa, :sha256, data, [sk, :secp256k1]) |> Base.encode16()
  end

  def verify(msg,sig,pk) do
    :crypto.verify(:ecdsa, :sha256,msg, sig |> Base.decode16! , [pk |> Base.decode16!, :secp256k1])
  end

  def generate() do
    private_key = :crypto.strong_rand_bytes(32)

    case valid?(private_key) do
      true -> private_key
      false -> generate()
    end
  end

  def to_public_key(private_key) do
    :crypto.generate_key(:ecdh, :crypto.ec_curve(:secp256k1), private_key)
    |> elem(0) |> Base.encode16()
  end

  def to_public_hash(private_key) do
    private_key
    |> to_public_key
    |> hash(:sha256)
    |> hash(:ripemd160) |> Base.encode16()
  end


  def valid?(key) when is_binary(key) do
    key
    |> :binary.decode_unsigned()
    |> valid?
  end

  def valid?(key) when key > 1 and key < @max, do: true
  def valid?(_), do: false

  def hash(data, algorithm), do: :crypto.hash(algorithm, data)

end
