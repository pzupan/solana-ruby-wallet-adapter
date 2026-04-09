# frozen_string_literal: true
# typed: strict

module SolanaWalletAdapter
  # Hooks into Rails to auto-load configuration from
  # config/initializers/solana_wallet_adapter.rb (if present) and to expose
  # a controller helper module.
  class Railtie < Rails::Railtie
    # Expose helper methods in ActionController and ActionView.
    initializer "solana_wallet_adapter.action_controller" do
      ActiveSupport.on_load(:action_controller_base) do
        include SolanaWalletAdapter::ControllerHelpers
      end
    end

    initializer "solana_wallet_adapter.action_view" do
      ActiveSupport.on_load(:action_view) do
        include SolanaWalletAdapter::ViewHelpers
      end
    end
  end
end
