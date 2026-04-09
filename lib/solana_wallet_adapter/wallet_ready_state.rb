# frozen_string_literal: true
# typed: strict

module SolanaWalletAdapter
  # Mirrors the WalletReadyState enum from @solana/wallet-adapter-base.
  #
  # +Installed+    – The wallet browser extension / app was detected.
  # +NotDetected+  – No wallet detected in the current environment.
  # +Loadable+     – The wallet is always available (e.g. iOS deep-link redirect).
  # +Unsupported+  – The platform cannot support this wallet (server-side, etc.).
  class WalletReadyState < T::Enum
    enums do
      Installed    = new("Installed")
      NotDetected  = new("NotDetected")
      Loadable     = new("Loadable")
      Unsupported  = new("Unsupported")
    end
  end
end
