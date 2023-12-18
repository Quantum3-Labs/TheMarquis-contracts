#!/bin/bash
source .env

WORLD_ADDRESS=$(cat ../target/dev/manifest.json | jq -r '.world.address')
THE_MARQUIS_ACTIONS_ADDRESS=$(cat ../target/dev/manifest.json | jq -r '.contracts[] | select(.name == "actions" ).address')
USD_M_TOKEN_ADDRESS=$(cat ../target/dev/manifest.json | jq -r '.contracts[] | select(.name == "erc_systems" ).address')

echo -e '\n✨ Performing setup for the following : ✨'
echo -e "WORLD_ADDRESS: $WORLD_ADDRESS"
echo -e "THE_MARQUIS_ACTIONS_ADDRESS: $THE_MARQUIS_ACTIONS_ADDRESS"
echo -e "USD_M_TOKEN_ADDRESS: $USD_M_TOKEN_ADDRESS"

# VARIABLES
export STARKNET_ACCOUNT=../account/Account_Marquis.json
export STARKNET_KEYSTORE=../account/Signer_Marquis.json
export STARKNET_RPC=$DOJO_GOERLI_RPC_URL

# INITIALIZE
echo -e '\n✨ Initializing contracts✨'

starkli invoke $THE_MARQUIS_ACTIONS_ADDRESS initialize $USD_M_TOKEN_ADDRESS --keystore-password $PASSWORD --watch

starkli invoke $USD_M_TOKEN_ADDRESS initialize 0x557364204d617271756973 0x5573644d $WORLD_ADDRESS --keystore-password $PASSWORD --watch

echo -e '\n✨ Spawn first game✨'
starkli invoke $THE_MARQUIS_ACTIONS_ADDRESS spawn --keystore-password $PASSWORD --watch

echo -e '\n✨ Setup completed ✨'

# ## MINT
echo -e '\n✨ Mint USD Marquis ✨'
starkli invoke $USD_M_TOKEN_ADDRESS mint_ 0x031be432d79a570ccf17288e5aca2ac3884c4dc0558df1f455a7df3aa820147f 1000000000000000000000 0 --keystore-password $PASSWORD --watch


# ## APPROVE AND BET
echo -e '\n✨ Approve and Bet ✨'
starkli invoke $USD_M_TOKEN_ADDRESS approve $THE_MARQUIS_ACTIONS_ADDRESS 1000000000000000000000 0 --keystore-password $PASSWORD --watch

starkli invoke $THE_MARQUIS_ACTIONS_ADDRESS move 0 2 4 30 2 1000000 5000000 --keystore-password $PASSWORD  --watch

# ## WINNER

echo -e '\n✨ Winner the Roulette ✨'

starkli invoke $THE_MARQUIS_ACTIONS_ADDRESS set_winner 0 3 --keystore-password $PASSWORD --watch
