# frozen_string_literal: true

require "sorbet-runtime"
require "solana_wallet_adapter"

RSpec.configure do |config|
  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.order = :random
  Kernel.srand config.seed

  config.before(:each) do
    SolanaWalletAdapter::WalletRegistry.reset!
  end
end
