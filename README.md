# solana-ruby-wallet-adapter

A Ruby on Rails gem port of [@solana/wallet-adapter](https://github.com/pzupan/wallet-adapter), with [Sorbet](https://sorbet.org) static types throughout.

Provides:
- Wallet metadata (name, icon, URL) for seeding a frontend wallet picker
- Server-side Ed25519 signature verification
- [Sign-In-With-Solana (SIWS)](https://login.xyz/solana) challenge/verify helpers
- A typed adapter hierarchy that mirrors the original TypeScript classes

> **How it differs from the TypeScript original.** Browser-only features — DOM wallet detection, `window.phantom`, popup flows — have no server-side equivalent. The Ruby adapters serve as **metadata providers** for the frontend and **verifiers** for signatures returned by the browser wallet.

---

## Table of contents

1. [Installation](#installation)
2. [Setup](#setup)
3. [Usage](#usage)
   - [Seed wallets to the frontend](#1-seed-wallets-to-the-frontend)
   - [Simple message signing](#2-simple-message-signing-authentication)
   - [Sign-In-With-Solana (SIWS)](#3-sign-in-with-solana-siws)
   - [Send a pre-signed transaction](#4-send-a-pre-signed-transaction)
   - [Server-built stake transaction (React-free Rails + Stimulus)](#5-server-built-stake-transaction-react-free-rails--stimulus)
   - [Working with public keys](#6-working-with-public-keys)
   - [Networks](#7-networks)
4. [Writing a custom adapter](#writing-a-custom-adapter)
5. [Error reference](#error-reference)
6. [API reference](#api-reference)
7. [Development](#development)
8. [License](#license)

---

## Installation

Add to your `Gemfile`:

```ruby
gem "solana_ruby_wallet_adapter"
```

Then run:

```bash
bundle install
```

### Requirements

| Requirement | Version |
|---|---|
| Ruby | >= 3.2 |
| Rails | >= 7.0 (optional – auto-detected) |
| `sorbet-runtime` | >= 0.5 |
| `ed25519` | >= 1.2 |
| `base58` | >= 0.2 |

---

## Setup

Generate the initializer:

```bash
# create config/initializers/solana_wallet_adapter.rb manually, or copy the example below
```

```ruby
# config/initializers/solana_wallet_adapter.rb
SolanaWalletAdapter::WalletRegistry.register(
  SolanaWalletAdapter::Wallets::PhantomWalletAdapter,
  SolanaWalletAdapter::Wallets::SolflareWalletAdapter,
  SolanaWalletAdapter::Wallets::LedgerWalletAdapter,
  SolanaWalletAdapter::Wallets::CoinbaseWalletAdapter,
  SolanaWalletAdapter::Wallets::WalletConnectWalletAdapter,
)
```

That's it. The gem auto-loads its Railtie when Rails is present, so
`ControllerHelpers` and `ViewHelpers` are mixed in automatically.

---

## Usage

### 1. Seed wallets to the frontend

Render wallet metadata into your layout so the JavaScript wallet-picker knows
which wallets to offer and what icons to show:

```erb
<%# app/views/layouts/application.html.erb %>
<head>
  <%# ... %>
  <script>
    window.__SOLANA_WALLETS__ = <%= solana_wallets_json %>;
  </script>
</head>
```

`solana_wallets_json` returns a JSON array like:

```json
[
  {
    "name": "Phantom",
    "url": "https://phantom.app",
    "icon": "data:image/svg+xml;base64,...",
    "readyState": "Unsupported",
    "connected": false,
    "publicKey": null
  },
  { "name": "Solflare", ... },
  ...
]
```

Or fetch it from a dedicated endpoint:

```ruby
# config/routes.rb
get "/wallets", to: "wallets#index"
```

```ruby
# app/controllers/wallets_controller.rb
class WalletsController < ApplicationController
  def index
    render json: SolanaWalletAdapter::WalletRegistry.to_json_array
  end
end
```

---

### 2. Simple message signing (authentication)

**Flow:**
1. Server generates a nonce and stores it in the session.
2. Browser wallet signs `"Sign in to MyApp\nNonce: <nonce>"`.
3. Browser POSTs `{ public_key, message, signature }` to the server.
4. Server verifies the signature, then creates the session.

```ruby
# app/controllers/wallet_sessions_controller.rb
class WalletSessionsController < ApplicationController
  # GET /wallet_sessions/new
  # Returns a nonce for the client to include in the message it signs.
  def new
    session[:wallet_nonce] = SecureRandom.hex(16)
    render json: { nonce: session[:wallet_nonce] }
  end

  # POST /wallet_sessions
  # Body: { public_key: "...", message: "...", signature: "..." }
  def create
    expected_message = "Sign in to MyApp\nNonce: #{session[:wallet_nonce]}"

    unless params[:message] == expected_message
      return render json: { error: "Message mismatch" }, status: :unprocessable_entity
    end

    verify_wallet_signature!(
      public_key_b58: params.require(:public_key),
      message:        params.require(:message),
      signature_b64:  params.require(:signature),   # Base64-encoded 64-byte signature
    )

    session[:wallet_public_key] = params[:public_key]
    session.delete(:wallet_nonce)

    render json: { ok: true, public_key: params[:public_key] }

  rescue SolanaWalletAdapter::WalletSignMessageError => e
    render json: { error: "Invalid signature: #{e.message}" }, status: :unauthorized
  end

  # DELETE /wallet_sessions
  def destroy
    session.delete(:wallet_public_key)
    head :no_content
  end
end
```

Matching JavaScript (browser side, using any wallet adapter):

```js
// Sign the expected message with the connected wallet
const message  = new TextEncoder().encode(`Sign in to MyApp\nNonce: ${nonce}`);
const { signature } = await wallet.signMessage(message);

await fetch("/wallet_sessions", {
  method: "POST",
  headers: { "Content-Type": "application/json" },
  body: JSON.stringify({
    public_key: wallet.publicKey.toBase58(),
    message:    `Sign in to MyApp\nNonce: ${nonce}`,
    signature:  btoa(String.fromCharCode(...signature)),   // Base64
  }),
});
```

---

### 3. Sign-In-With-Solana (SIWS)

SIWS is the Solana equivalent of [EIP-4361](https://eips.ethereum.org/EIPS/eip-4361).
It produces a structured, human-readable message that the wallet displays before
signing.

#### 3a. Issue a challenge

```ruby
# GET /siws/challenge
# Returns the SIWS message string and the input fields needed to verify later.
def challenge
  input = SolanaWalletAdapter::SignInInput.new(
    domain:    request.host,
    address:   params.require(:address),   # wallet public key (Base58)
    statement: "Sign in to #{Rails.application.class.module_parent_name}",
    uri:       root_url,
    version:   "1",
    nonce:     SecureRandom.hex(16),
    issued_at: Time.now.utc.iso8601,
    expiration_time: 10.minutes.from_now.utc.iso8601,
  )

  # Store the input in the session so the verify step can reconstruct it.
  session[:siws_input] = {
    domain:          input.domain,
    address:         input.address,
    statement:       input.statement,
    uri:             input.uri,
    version:         input.version,
    nonce:           input.nonce,
    issued_at:       input.issued_at,
    expiration_time: input.expiration_time,
  }

  render json: { message: input.to_message, input: session[:siws_input] }
end
```

`input.to_message` produces:

```
example.com wants you to sign in with your Solana account:
9noXzpXnLTia8oBHFMza9tqPuFvPpRCtAfJmZeoBc7x2

Sign in to MyApp

URI: https://example.com/
Version: 1
Nonce: a3f1b2c8d4e5f6a7
Issued At: 2024-06-01T12:00:00Z
Expiration Time: 2024-06-01T12:10:00Z
```

#### 3b. Verify the signed response

```ruby
# POST /siws/verify
# Body: { output: { address:, signed_message:, signature: } }
def verify
  stored_input = session[:siws_input]
  return render json: { error: "No active SIWS challenge" }, status: :bad_request if stored_input.nil?

  verify_sign_in!(
    input_params:  stored_input,
    output_params: params.require(:output).to_unsafe_h,
    # output must contain:
    #   address:        the signer's Base58 public key
    #   signed_message: the exact SIWS message that was signed (UTF-8 string)
    #   signature:      Base64-encoded 64-byte Ed25519 signature
  )

  session[:wallet_public_key] = params.dig(:output, :address)
  session.delete(:siws_input)

  render json: { ok: true }

rescue SolanaWalletAdapter::WalletSignInError => e
  render json: { error: e.message }, status: :unauthorized
end
```

Matching JavaScript:

```js
// 1. Fetch the challenge
const { message, input } = await fetch(`/siws/challenge?address=${publicKey}`).then(r => r.json());

// 2. Sign with wallet
const encoded   = new TextEncoder().encode(message);
const { signature } = await wallet.signMessage(encoded);

// 3. POST the output
await fetch("/siws/verify", {
  method: "POST",
  headers: { "Content-Type": "application/json" },
  body: JSON.stringify({
    output: {
      address:        publicKey.toBase58(),
      signed_message: message,
      signature:      btoa(String.fromCharCode(...signature)),
    },
  }),
});
```

---

### 4. Send a pre-signed transaction

For use cases where the browser signs a transaction and the server forwards it
to the RPC (e.g., sponsored transactions, relayers):

```ruby
# POST /transactions
# Body: { signed_tx: "<Base64-encoded serialised transaction>" }
def submit
  raw_bytes = Base64.strict_decode64(params.require(:signed_tx))
  tx        = SolanaWalletAdapter::Transaction.new(raw_bytes)

  rpc_url   = SolanaWalletAdapter::Network::MainnetBeta.rpc_url
  options   = SolanaWalletAdapter::SendTransactionOptions.new(
    skip_preflight:       false,
    preflight_commitment: "confirmed",
  )

  # BaseSignerWalletAdapter#send_raw_transaction posts the bytes to the RPC.
  # Since the tx is already signed, instantiate a pass-through adapter helper:
  signature = SolanaWalletAdapter::RpcClient.new(rpc_url).send_raw_transaction(raw_bytes, options)

  render json: { signature: signature }
rescue SolanaWalletAdapter::WalletSendTransactionError => e
  render json: { error: e.message }, status: :unprocessable_entity
end
```

Or call the RPC directly from any adapter instance using the protected helper:

```ruby
adapter = SolanaWalletAdapter::Wallets::PhantomWalletAdapter.new
# (internal method, exposed here for illustration)
signature = adapter.send(:send_raw_transaction, raw_bytes, rpc_url, options)
```

---

### 5. Server-built stake transaction (React-free Rails + Stimulus)

This example shows how to build a Solana staking UI without React.
The transaction is constructed and partially signed on the server using
[solana-ruby-kit](https://github.com/pzupan/solana-ruby-kit), then sent to
the browser for the user's wallet signature.  This gem seeds the wallet
picker and handles any server-side signature work.

**Flow:**
1. Rails layout seeds registered wallet metadata into `window.__SOLANA_WALLETS__`.
2. A Stimulus controller detects the wallet, connects, and collects the SOL amount.
3. The browser POSTs `{ public_key, sol }` to a Rails endpoint.
4. The Rails controller builds a `createAccount + initialize + delegate` transaction,
   partially signs it with the generated stake-account keypair, and returns
   the wire bytes as Base64.
5. The Stimulus controller passes the bytes to the wallet for the user's signature,
   then broadcasts the fully-signed transaction.

#### Layout — seed wallet metadata

```erb
<%# app/views/layouts/application.html.erb %>
<head>
  <%# ... %>
  <script>window.__SOLANA_WALLETS__ = <%= solana_wallets_json.html_safe %>;</script>
</head>
```

#### Initializer — register adapters

```ruby
# config/initializers/solana_wallet_adapter.rb
SolanaWalletAdapter::WalletRegistry.register(
  SolanaWalletAdapter::Wallets::PhantomWalletAdapter,
  SolanaWalletAdapter::Wallets::SolflareWalletAdapter,
  SolanaWalletAdapter::Wallets::LedgerWalletAdapter,
  SolanaWalletAdapter::Wallets::CoinbaseWalletAdapter,
  SolanaWalletAdapter::Wallets::WalletConnectWalletAdapter,
)
```

#### Rails controller — build and partially sign the transaction

```ruby
# app/controllers/staking_controller.rb
require 'base64'

class StakingController < ApplicationController
  VOTE_ACCOUNT = '26RGqX3mezgYDxJnGh94gnMM4L2k9grH1eWcTSCHnaxR'
  RPC_URL      = 'https://api.mainnet-beta.solana.com'

  # POST /staking/prepare
  def prepare
    public_key = params.require(:public_key)
    lamports   = (params.require(:sol).to_f * 1_000_000_000).to_i

    rpc              = Solana::Ruby::Kit::Rpc::Client.new(RPC_URL)
    blockhash_result = rpc.get_latest_blockhash
    blockhash        = blockhash_result.value.blockhash
    last_valid       = blockhash_result.value.last_valid_block_height

    owner         = Solana::Ruby::Kit::Addresses::Address.new(public_key)
    stake_kp      = Solana::Ruby::Kit::Keys.generate_key_pair
    stake_address = Solana::Ruby::Kit::Addresses::Address.new(
      Solana::Ruby::Kit::Encoding::Base58.encode(stake_kp.verify_key.to_bytes)
    )

    create_ixs = Solana::Ruby::Kit::Programs::StakeProgram.create_account_instructions(
      from:          owner,
      stake_account: stake_address,
      authorized:    owner,
      lamports:      lamports
    )

    delegate_ix = Solana::Ruby::Kit::Programs::StakeProgram.delegate_instruction(
      stake_account: stake_address,
      vote_account:  Solana::Ruby::Kit::Addresses::Address.new(VOTE_ACCOUNT),
      authorized:    owner
    )

    message = Solana::Ruby::Kit::TransactionMessages::TransactionMessage.new(
      version:             :legacy,
      instructions:        create_ixs + [delegate_ix],
      fee_payer:           owner,
      lifetime_constraint: Solana::Ruby::Kit::TransactionMessages::BlockhashLifetimeConstraint.new(
        blockhash:               blockhash,
        last_valid_block_height: last_valid
      )
    )

    tx = Solana::Ruby::Kit::Transactions.compile_transaction_message(message)
    tx = Solana::Ruby::Kit::Transactions.partially_sign_transaction([stake_kp.signing_key], tx)

    wire_bytes = Solana::Ruby::Kit::Transactions.wire_encode_transaction(tx)
    render json: { transaction: Base64.strict_encode64(wire_bytes) }
  rescue => e
    render json: { error: e.message }, status: :unprocessable_entity
  end
end
```

#### Route

```ruby
# config/routes.rb
post '/staking/prepare', to: 'staking#prepare'
```

#### ViewComponent — Stimulus markup

```erb
<%# app/components/stake_button/show_component.html.erb %>
<div data-controller="stake">
  <button
    class="btn btn-outline-primary w-100 mb-3"
    data-action="click->stake#connectWallet"
    data-stake-target="connectButton">
    Select Wallet
  </button>

  <input
    type="number"
    class="form-control mb-3"
    data-stake-target="input"
    disabled
    value="1"
    min="0.01"
    step="0.01"
  />

  <button
    class="btn btn-primary w-100"
    data-action="click->stake#stake"
    data-stake-target="stakeButton"
    disabled>
    Stake Now
  </button>

  <p class="mt-2 small text-muted" data-stake-target="status"></p>
</div>
```

#### Stimulus controller — wallet connection and signing

```js
// app/javascript/controllers/stake_controller.js
import { Controller } from "@hotwired/stimulus"
import { Connection, Transaction } from "@solana/web3.js"

const RPC_URL = "https://api.mainnet-beta.solana.com"

export default class extends Controller {
  static targets = ["connectButton", "input", "stakeButton", "status"]

  connect() {
    this.provider   = null
    this.publicKey  = null
    this.connection = new Connection(RPC_URL, "confirmed")
    this.detectWallet()
  }

  detectWallet() {
    if (window.phantom?.solana?.isPhantom)  this.provider = window.phantom.solana
    else if (window.solana?.isPhantom)      this.provider = window.solana
    else if (window.solflare?.isSolflare)   this.provider = window.solflare
  }

  async connectWallet() {
    if (!this.provider) this.detectWallet()
    if (!this.provider) {
      this.setStatus("No Solana wallet found. Please install Phantom or Solflare.")
      return
    }
    try {
      this.setStatus("Connecting…")
      const resp     = await this.provider.connect()
      this.publicKey = resp.publicKey.toString()
      this.connectButtonTarget.textContent =
        `${this.publicKey.slice(0, 6)}…${this.publicKey.slice(-4)}`
      this.inputTarget.disabled       = false
      this.stakeButtonTarget.disabled = false
      this.setStatus("")
    } catch (e) {
      this.setStatus(`Connect failed: ${e.message}`)
    }
  }

  async stake() {
    if (!this.publicKey) return

    const sol = parseFloat(this.inputTarget.value || "0")
    if (sol <= 0) { this.setStatus("Enter a valid SOL amount."); return }

    this.stakeButtonTarget.disabled = true
    this.setStatus("Building transaction…")

    try {
      const csrfToken = document.querySelector("meta[name='csrf-token']").content
      const resp = await fetch("/staking/prepare", {
        method:  "POST",
        headers: { "Content-Type": "application/json", "X-CSRF-Token": csrfToken },
        body:    JSON.stringify({ public_key: this.publicKey, sol }),
      })
      const data = await resp.json()
      if (data.error) throw new Error(data.error)

      this.setStatus("Awaiting wallet signature…")
      const txBytes  = Uint8Array.from(atob(data.transaction), c => c.charCodeAt(0))
      const tx       = Transaction.from(txBytes)
      const signedTx = await this.provider.signTransaction(tx)

      this.setStatus("Broadcasting…")
      const sig = await this.connection.sendRawTransaction(signedTx.serialize())
      await this.connection.confirmTransaction(sig, "confirmed")
      this.setStatus(`Staked! Tx: ${sig.slice(0, 20)}…`)
    } catch (e) {
      this.setStatus(`Error: ${e.message}`)
      this.stakeButtonTarget.disabled = false
    }
  }

  setStatus(msg) {
    if (this.hasStatusTarget) this.statusTarget.textContent = msg
  }
}
```

> **Note:** `@solana/web3.js` is still needed in the browser to deserialize the
> server-built transaction (`Transaction.from`) and broadcast it via
> `sendRawTransaction`.  All React and `@solana/wallet-adapter-react*` packages
> can be removed from `package.json`.

---

### 6. Working with public keys


```ruby
# From a Base58 string (most common – what wallets return)
pk = SolanaWalletAdapter::PublicKey.new("9noXzpXnLTia8oBHFMza9tqPuFvPpRCtAfJmZeoBc7x2")
pk.to_base58   # => "9noXzpXnLTia8oBHFMza9tqPuFvPpRCtAfJmZeoBc7x2"
pk.to_bytes    # => [138, 12, ...]   Array of 32 integers
pk.bytes       # => "\x8a\x0c..."   raw 32-byte binary String

# From a raw binary string (e.g. decoded from a transaction)
pk = SolanaWalletAdapter::PublicKey.new("\x00" * 32)

# From a Uint8Array-style Integer array
pk = SolanaWalletAdapter::PublicKey.new([0] * 32)

# Equality
pk1 = SolanaWalletAdapter::PublicKey.new("11111111111111111111111111111111")
pk2 = SolanaWalletAdapter::PublicKey.new([0] * 32)
pk1 == pk2   # => true  (System Program address)
```

---

### 7. Networks

```ruby
net = SolanaWalletAdapter::Network::MainnetBeta
net.serialize   # => "mainnet-beta"
net.rpc_url     # => "https://api.mainnet-beta.solana.com"

SolanaWalletAdapter::Network::Devnet.rpc_url
# => "https://api.devnet.solana.com"

SolanaWalletAdapter::Network::Testnet.rpc_url
# => "https://api.testnet.solana.com"
```

---

## Writing a custom adapter

Subclass `BaseMessageSignerWalletAdapter` (for sign + message), or
`BaseSignerWalletAdapter` (sign only), or `BaseWalletAdapter` (metadata only):

```ruby
# typed: strict
# app/solana/my_custom_wallet_adapter.rb

class MyCustomWalletAdapter < SolanaWalletAdapter::BaseMessageSignerWalletAdapter
  extend T::Sig

  sig { override.returns(String) }
  def name = "MyWallet"

  sig { override.returns(String) }
  def url = "https://mywallet.example.com"

  sig { override.returns(String) }
  def icon = "data:image/svg+xml;base64,PHN2Zy..."

  sig { override.returns(SolanaWalletAdapter::WalletReadyState) }
  def ready_state = SolanaWalletAdapter::WalletReadyState::Unsupported

  sig { override.returns(T.nilable(SolanaWalletAdapter::PublicKey)) }
  def public_key = nil

  sig { override.returns(T::Boolean) }
  def connecting? = false

  sig { override.returns(SolanaWalletAdapter::SupportedTransactionVersions) }
  def supported_transaction_versions
    Set[
      SolanaWalletAdapter::TransactionVersion::Legacy,
      SolanaWalletAdapter::TransactionVersion::Version0,
    ].freeze
  end

  sig { override.void }
  def connect
    raise SolanaWalletAdapter::WalletNotReadyError,
          "#{name} connection is initiated in the browser"
  end

  sig { override.void }
  def disconnect; end

  sig do
    override
      .params(
        transaction: SolanaWalletAdapter::Transaction,
        rpc_url:     String,
        options:     SolanaWalletAdapter::SendTransactionOptions,
      )
      .returns(String)
  end
  def send_transaction(transaction, rpc_url, options = SolanaWalletAdapter::SendTransactionOptions.new)
    raise SolanaWalletAdapter::WalletNotConnectedError
  end

  sig { override.params(transaction: SolanaWalletAdapter::Transaction).returns(SolanaWalletAdapter::Transaction) }
  def sign_transaction(transaction)
    raise SolanaWalletAdapter::WalletNotConnectedError
  end

  sig { override.params(transactions: T::Array[SolanaWalletAdapter::Transaction]).returns(T::Array[SolanaWalletAdapter::Transaction]) }
  def sign_all_transactions(transactions)
    raise SolanaWalletAdapter::WalletNotConnectedError
  end

  sig { override.params(message: String).returns(String) }
  def sign_message(message)
    raise SolanaWalletAdapter::WalletNotConnectedError
  end
end
```

Register it:

```ruby
# config/initializers/solana_wallet_adapter.rb
SolanaWalletAdapter::WalletRegistry.register(MyCustomWalletAdapter)
```

---

## Error reference

All errors inherit from `SolanaWalletAdapter::WalletError < StandardError`.

| Class | When raised |
|---|---|
| `WalletNotReadyError` | Wallet not installed / not in a connectable state |
| `WalletLoadError` | Wallet extension failed to load |
| `WalletConfigError` | Adapter misconfiguration |
| `WalletConnectionError` | Connection attempt failed |
| `WalletDisconnectedError` | Wallet disconnected unexpectedly |
| `WalletDisconnectionError` | Explicit disconnect request failed |
| `WalletAccountError` | Wallet returned an unexpected account |
| `WalletPublicKeyError` | Wallet returned an invalid public key |
| `WalletKeypairError` | Keypair-level error |
| `WalletNotConnectedError` | Operation requires a connected wallet |
| `WalletSendTransactionError` | Sending a transaction failed |
| `WalletSignTransactionError` | Signing a transaction failed |
| `WalletSignMessageError` | Signing a message failed / signature invalid |
| `WalletSignInError` | SIWS flow failed (mismatch or bad signature) |
| `WalletTimeoutError` | Operation timed out |
| `WalletWindowBlockedError` | Popup window was blocked |
| `WalletWindowClosedError` | User closed the wallet popup |

All errors accept an optional second argument `cause_error`:

```ruby
raise SolanaWalletAdapter::WalletConnectionError.new("Could not connect", original_exception)
```

---

## API reference

### `WalletRegistry`

```ruby
WalletRegistry.register(*adapter_classes)   # register one or more adapter classes
WalletRegistry.all                          # => Array of adapter classes
WalletRegistry.find("Phantom")              # => PhantomWalletAdapter class or nil
WalletRegistry.to_json_array               # => Array<Hash> ready for JSON serialisation
WalletRegistry.reset!                       # clear all (useful in tests)
```

### `SignatureVerifier`

```ruby
verifier = SolanaWalletAdapter::SignatureVerifier.new

# Returns true/false
verifier.verify(public_key: pk, message: msg, signature: sig)

# Raises WalletSignMessageError on failure
verifier.verify!(public_key: pk, message: msg, signature: sig)

# Raises WalletSignInError on failure
verifier.verify_sign_in!(input: sign_in_input, output: sign_in_output)
```

### `SignInInput`

```ruby
input = SolanaWalletAdapter::SignInInput.new(
  domain:          "example.com",          # required
  address:         "9noX...",              # required – Base58 public key
  statement:       "Sign in to MyApp",     # optional
  uri:             "https://example.com/", # optional
  version:         "1",                    # default "1"
  nonce:           "abc123",               # optional but recommended
  issued_at:       Time.now.utc.iso8601,   # optional
  expiration_time: 10.minutes.from_now.utc.iso8601, # optional
  not_before:      nil,                    # optional
  request_id:      nil,                    # optional
  resources:       [],                     # optional Array<String>
)

input.to_message   # => canonical SIWS message string to sign
```

### `PublicKey`

```ruby
SolanaWalletAdapter::PublicKey.new(base58_string)
SolanaWalletAdapter::PublicKey.new(binary_string)   # 32-byte binary
SolanaWalletAdapter::PublicKey.new(integer_array)   # 32-element Array<Integer>

pk.to_base58   # => String
pk.to_bytes    # => Array<Integer>
pk.bytes       # => String (binary)
pk == other_pk # => Boolean
```

### `Transaction`

```ruby
SolanaWalletAdapter::Transaction.new(wire_bytes, version: nil)

tx.versioned?   # => true for Version0, false for Legacy/nil
tx.serialize    # => wire_bytes
tx.version      # => TransactionVersion or nil
```

### `SendTransactionOptions`

```ruby
SolanaWalletAdapter::SendTransactionOptions.new(
  signers:               [],          # Array<String> additional signer keypairs
  preflight_commitment:  "confirmed", # String or nil
  skip_preflight:        false,
  max_retries:           nil,
  min_context_slot:      nil,
)
```

---

## Development

```bash
bundle install
bundle exec rspec          # run tests
bundle exec srb tc         # Sorbet type-check
```

To add more wallet adapters, copy `lib/solana_wallet_adapter/wallets/phantom.rb`
as a template and register the new class in the initializer.

---

## License

Apache-2.0 — same as the original TypeScript library.
