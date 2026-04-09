# frozen_string_literal: true
# typed: strict

module SolanaWalletAdapter
  # Helpers mixed into ActionController::Base when the Railtie loads.
  module ControllerHelpers
    extend T::Sig

    # Verify a Solana message signature submitted from the browser.
    # Raises WalletSignMessageError if verification fails.
    #
    # Params:
    #   public_key_b58 – Base58 string of the signer's public key
    #   message        – the original UTF-8 message string
    #   signature_b64  – Base64-encoded 64-byte Ed25519 signature
    sig do
      params(
        public_key_b58: String,
        message:        String,
        signature_b64:  String
      ).void
    end
    def verify_wallet_signature!(public_key_b58:, message:, signature_b64:)
      require "base64"
      public_key = PublicKey.new(public_key_b58)
      signature  = Base64.strict_decode64(signature_b64)
      SignatureVerifier.new.verify!(
        public_key: public_key,
        message:    message,
        signature:  signature
      )
    end

    # Verify a Sign-In-With-Solana output POSTed from the browser.
    # Raises WalletSignInError if verification fails.
    sig do
      params(
        input_params:  T::Hash[String, T.untyped],
        output_params: T::Hash[String, T.untyped]
      ).void
    end
    def verify_sign_in!(input_params:, output_params:)
      require "base64"

      input = SignInInput.new(
        domain:          input_params.fetch("domain"),
        address:         input_params.fetch("address"),
        statement:       input_params["statement"],
        uri:             input_params["uri"],
        version:         input_params.fetch("version", "1"),
        nonce:           input_params["nonce"],
        issued_at:       input_params["issued_at"],
        expiration_time: input_params["expiration_time"],
        not_before:      input_params["not_before"],
        request_id:      input_params["request_id"],
        resources:       Array(input_params["resources"]),
      )

      output = SignInOutput.new(
        address:        output_params.fetch("address"),
        signed_message: output_params.fetch("signed_message"),
        signature:      Base64.strict_decode64(output_params.fetch("signature")),
        signature_type: output_params.fetch("signature_type", "ed25519"),
      )

      SignatureVerifier.new.verify_sign_in!(input: input, output: output)
    end
  end
end
