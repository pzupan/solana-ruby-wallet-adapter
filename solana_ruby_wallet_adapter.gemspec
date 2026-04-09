# frozen_string_literal: true

require_relative "lib/solana_wallet_adapter/version"

Gem::Specification.new do |spec|
  spec.name    = "solana_ruby_wallet_adapter"
  spec.version = SolanaWalletAdapter::VERSION
  spec.authors = ["pzupan"]
  spec.email   = []

  spec.summary     = "Modular Solana wallet adapters for Ruby on Rails"
  spec.description = <<~DESC
    A Ruby port of @solana/wallet-adapter. Provides typed wallet adapter
    abstractions, server-side signature verification, Sign-In-With-Solana
    (SIWS) helpers, and a wallet registry for Rails applications.
  DESC
  spec.homepage = "https://github.com/pzupan/solana-ruby-wallet-adapter"
  spec.license  = "Apache-2.0"

  spec.required_ruby_version = ">= 3.2"

  spec.metadata["homepage_uri"]    = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage

  spec.files = Dir[
    "lib/**/*.rb",
    "sig/**/*.rbi",
    "sorbet/**/*",
    "LICENSE",
    "README.md",
  ]

  spec.require_paths = ["lib"]

  # Sorbet runtime for typed Ruby
  spec.add_dependency "sorbet-runtime", ">= 0.5"

  # Ed25519 signature verification for Solana public keys / signatures
  spec.add_dependency "ed25519", ">= 1.2"

  # Base58 encoding/decoding for Solana public keys and signatures
  spec.add_dependency "base58", ">= 0.2"

  # Rails integration (optional – only loaded when Rails is present)
  spec.add_development_dependency "rails", ">= 7.0"
  spec.add_development_dependency "sorbet", ">= 0.5"
  spec.add_development_dependency "tapioca", ">= 0.11"
  spec.add_development_dependency "rspec", ">= 3.12"
  spec.add_development_dependency "rspec-rails", ">= 6.0"
end
