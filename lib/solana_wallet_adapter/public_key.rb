# frozen_string_literal: true
# typed: strict

require "base58"

module SolanaWalletAdapter
  # Lightweight representation of a Solana public key.
  # A Solana public key is a 32-byte Ed25519 public key encoded as Base58.
  class PublicKey
    extend T::Sig

    BYTE_LENGTH = T.let(32, Integer)

    sig { returns(String) }
    attr_reader :bytes # raw 32-byte binary string

    # Accepts a Base58-encoded string, a raw 32-byte binary string, or a
    # 32-element Integer array (matching the JS Uint8Array constructor).
    sig { params(value: T.any(String, T::Array[Integer])).void }
    def initialize(value)
      @bytes = T.let(decode(value), String)
      raise ArgumentError, "Public key must be #{BYTE_LENGTH} bytes" unless @bytes.bytesize == BYTE_LENGTH
    end

    sig { returns(String) }
    def to_base58
      Base58.binary_to_base58(@bytes, :bitcoin)
    end

    alias to_s to_base58

    sig { returns(T::Array[Integer]) }
    def to_bytes
      @bytes.bytes
    end

    sig { params(other: PublicKey).returns(T::Boolean) }
    def ==(other)
      other.is_a?(PublicKey) && bytes == other.bytes
    end

    sig { returns(Integer) }
    def hash
      bytes.hash
    end

    sig { returns(String) }
    def inspect
      "#<#{self.class} #{to_base58}>"
    end

    private

    sig { params(value: T.any(String, T::Array[Integer])).returns(String) }
    def decode(value)
      case value
      when Array
        value.pack("C*")
      when String
        # Detect binary vs Base58: binary strings are 32 bytes, Base58 strings
        # are 32–44 ASCII characters.
        if value.encoding == Encoding::BINARY || value.bytesize == BYTE_LENGTH
          value.b
        else
          Base58.base58_to_binary(value, :bitcoin)
        end
      else
        T.absurd(value)
      end
    end
  end
end
