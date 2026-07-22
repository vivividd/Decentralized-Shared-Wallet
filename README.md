# Shared Wallet

A small ETH-based wallet built with Solidity and some minimalistic frontend :)

## What can u do with it?

- Submit, approve, revoke, and execute transactions.
- Add/remove owners and change the approval threshold through multisig transactions.
- Accept ETH and arbitrary contract calldata.

## How to run tests to verify that everything works?

```sh
forge build
forge fmt --check
forge test
```

## How to deploy?

Copy `.env.example` to `.env` and set `OWNERS` and `REQUIRED_APPROVALS`.

```sh
source .env
forge script script/Deploy.s.sol:Deploy \
  --rpc-url "$RPC_URL" \
  --private-key "$PRIVATE_KEY" \
  --broadcast
```

## Frontend part (I am not really strong in that sense so Codex helped me...)

```sh
python3 -m http.server 4173
```

Open [http://127.0.0.1:4173/frontend/](http://127.0.0.1:4173/frontend/), connect an owner wallet, and enter the deployed contract address.
