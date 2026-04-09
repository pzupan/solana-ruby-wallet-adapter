# frozen_string_literal: true
# typed: strict

module SolanaWalletAdapter
  # Helpers mixed into ActionView::Base when the Railtie loads.
  module ViewHelpers
    extend T::Sig

    # Returns a JSON array of all registered wallet adapter metadata.
    # Useful for seeding a JS wallet picker component.
    #
    # Example (in an ERB layout):
    #   <script>
    #     window.__SOLANA_WALLETS__ = <%= solana_wallets_json %>;
    #   </script>
    sig { returns(String) }
    def solana_wallets_json
      require "json"
      JSON.generate(WalletRegistry.to_json_array)
    end
  end
end
