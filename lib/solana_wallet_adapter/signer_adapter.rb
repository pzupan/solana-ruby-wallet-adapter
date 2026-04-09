# frozen_string_literal: true
# typed: strict

module SolanaWalletAdapter
  # Mixin for adapters that can sign transactions locally (without sending).
  # Mirrors SignerWalletAdapterProps from @solana/wallet-adapter-base.
  module SignerWalletAdapter
    extend T::Sig
    extend T::Helpers

    requires_ancestor { BaseWalletAdapter }

    # Sign a single transaction and return the signed bytes.
    sig do
      abstract
        .params(transaction: Transaction)
        .returns(Transaction)
    end
    def sign_transaction(transaction); end

    # Sign multiple transactions and return them in the same order.
    sig do
      abstract
        .params(transactions: T::Array[Transaction])
        .returns(T::Array[Transaction])
    end
    def sign_all_transactions(transactions); end
  end

  # Abstract base class that combines BaseWalletAdapter with signing.
  # Mirrors BaseSignerWalletAdapter from @solana/wallet-adapter-base.
  class BaseSignerWalletAdapter < BaseWalletAdapter
    extend  T::Sig
    extend  T::Helpers
    include SignerWalletAdapter

    abstract!

    # send_transaction default implementation: sign then forward raw bytes
    # to the Solana RPC via Net::HTTP.  Subclasses may override.
    sig do
      override
        .params(
          transaction: Transaction,
          rpc_url:     String,
          options:     SendTransactionOptions
        )
        .returns(String)
    end
    def send_transaction(transaction, rpc_url, options = SendTransactionOptions.new)
      raise WalletNotConnectedError unless connected?

      if transaction.versioned?
        unless supported_transaction_versions
          raise WalletSendTransactionError,
                "Sending versioned transactions isn't supported by this wallet"
        end
        unless T.must(supported_transaction_versions).include?(T.must(transaction.version))
          raise WalletSendTransactionError,
                "Sending transaction version #{transaction.version&.serialize} isn't supported by this wallet"
        end
      end

      signed = begin
        sign_transaction(transaction)
      rescue WalletSignTransactionError
        raise
      rescue => e
        raise WalletSendTransactionError.new(e.message, e)
      end

      send_raw_transaction(signed.serialize, rpc_url, options)
    rescue WalletError => e
      emit(:error, e)
      raise
    end

    private

    # Submits serialised transaction bytes to the RPC endpoint and returns
    # the transaction signature string.
    sig { params(raw_bytes: String, rpc_url: String, options: SendTransactionOptions).returns(String) }
    def send_raw_transaction(raw_bytes, rpc_url, options)
      require "net/http"
      require "json"
      require "base64"

      encoded = Base64.strict_encode64(raw_bytes)

      config = [encoded, { encoding: "base64" }]
      config[1]["skipPreflight"]         = options.skip_preflight if options.skip_preflight
      config[1]["preflightCommitment"]   = options.preflight_commitment if options.preflight_commitment
      config[1]["maxRetries"]            = options.max_retries if options.max_retries
      config[1]["minContextSlot"]        = options.min_context_slot if options.min_context_slot

      body = JSON.generate({
        jsonrpc: "2.0",
        id:      1,
        method:  "sendTransaction",
        params:  config,
      })

      uri      = URI(rpc_url)
      response = Net::HTTP.post(uri, body, "Content-Type" => "application/json")
      result   = JSON.parse(response.body)

      if (err = result["error"])
        raise WalletSendTransactionError, err["message"] || err.inspect
      end

      result.dig("result") || raise(WalletSendTransactionError, "Unexpected RPC response: #{result.inspect}")
    end
  end
end
