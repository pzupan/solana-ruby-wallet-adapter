# frozen_string_literal: true
# typed: strict

require "sorbet-runtime"
require "set"

# Core infrastructure
require_relative "solana_wallet_adapter/version"
require_relative "solana_wallet_adapter/errors"
require_relative "solana_wallet_adapter/network"
require_relative "solana_wallet_adapter/public_key"
require_relative "solana_wallet_adapter/transaction"
require_relative "solana_wallet_adapter/wallet_ready_state"
require_relative "solana_wallet_adapter/event_emitter"

# Adapter hierarchy
require_relative "solana_wallet_adapter/adapter"
require_relative "solana_wallet_adapter/signer_adapter"
require_relative "solana_wallet_adapter/message_signer_adapter"

# Server-side signature verification
require_relative "solana_wallet_adapter/signature_verifier"

# Wallet registry
require_relative "solana_wallet_adapter/wallet_registry"

# Wallet adapter implementations
require_relative "solana_wallet_adapter/wallets/phantom"
require_relative "solana_wallet_adapter/wallets/solflare"
require_relative "solana_wallet_adapter/wallets/ledger"
require_relative "solana_wallet_adapter/wallets/coinbase"
require_relative "solana_wallet_adapter/wallets/walletconnect"

# Rails integration (only when Rails is available)
if defined?(Rails)
  require_relative "solana_wallet_adapter/controller_helpers"
  require_relative "solana_wallet_adapter/view_helpers"
  require_relative "solana_wallet_adapter/railtie"
end
