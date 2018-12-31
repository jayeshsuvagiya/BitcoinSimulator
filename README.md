# Bitcoin Simulation
A simulation of blockchain and bitcoin protocol with multiple miners and nodes using elixir and phoenix. 

## Demo Video
https://drive.google.com/open?id=1oLTGS2SirCUsvRFWndUk6M9sKa2_5mgf

![alt text](https://drive.google.com/uc?id=1iZAzj4_aRKtXtVgsQfcFEJxn4DilkJjt)

![alt text](https://drive.google.com/uc?id=1jVjS6iHuTg94Hk4o4NjJnkKPLbUjUSJK)

![alt text](https://drive.google.com/uc?id=1TLC5EGtq2Ii4f1UHBA-Kwpgi2mJtZho5)

## Functionality Implemented -
1. Crypto Module - hash, double hash, signature, verification, random public key private key generation.
2. Transaction Module - Creating transactions , Serialize and Calculate Hash, Add input transactions, add output transactions, create input/output transaction.
3. Block Module - Create Genesis block, Mine Block Synchronously, Create new blocks, Serialize and calculate hash, Add transactions to existing block.
4. Miner Module - Mine Async so that node can listen for transactions and block messages.
5. Node - Listen for transaction, Listen for blocks, Maintain Main blockchain, side branch and orphan blocks, Coordinate with child miner task, send bitcoins, check balance.
6. Front End - Javascript and node js modules, chart js library, css themes, socket connection, listen to channel update messages.
7. Backend - phoenix controller, templates for main page, template for table row, broadcasting various messages to socket endpoints.
8. (rest please see the video for detail explanation.)

## usage
Run following command - mix phx.server

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.
