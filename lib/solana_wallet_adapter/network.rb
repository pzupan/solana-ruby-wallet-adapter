# frozen_string_literal: true
# typed: strict

module SolanaWalletAdapter
  # Mirrors WalletAdapterNetwork from @solana/wallet-adapter-base.
  class Network < T::Enum
    extend T::Sig

    enums do
      MainnetBeta = new("mainnet-beta")
      Testnet     = new("testnet")
      Devnet      = new("devnet")
    end

    # The RPC cluster URL commonly associated with each network.
    RPC_URLS = T.let(
      {
        MainnetBeta => "https://api.mainnet-beta.solana.com",
        Testnet     => "https://api.testnet.solana.com",
        Devnet      => "https://api.devnet.solana.com",
      }.freeze,
      T::Hash[Network, String]
    )

    sig { returns(String) }
    def rpc_url
      RPC_URLS.fetch(self)
    end
  end
end
