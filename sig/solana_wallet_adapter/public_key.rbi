# typed: true

module SolanaWalletAdapter
  class PublicKey
    BYTE_LENGTH = T.let(32, Integer)

    sig { returns(String) }
    def bytes; end

    sig { params(value: T.any(String, T::Array[Integer])).void }
    def initialize(value); end

    sig { returns(String) }
    def to_base58; end

    sig { returns(String) }
    def to_s; end

    sig { returns(T::Array[Integer]) }
    def to_bytes; end

    sig { params(other: PublicKey).returns(T::Boolean) }
    def ==(other); end
  end
end
