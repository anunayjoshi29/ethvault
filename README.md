# ETHVault - Ethereum Staking & Governance Platform

ETHVault is a decentralized platform for Ethereum staking, governance, and participation in the Ethereum ecosystem. It allows users to stake ETH, earn rewards, and vote on proposals that shape the future of the protocol.

## Technology Stack

- **Frontend**: Next.js, React, TypeScript, Tailwind CSS
- **Backend**: Node.js, Express.js
- **Blockchain Interaction**: ethers.js
- **Smart Contracts**: Solidity (ERC20-based tokens)
- **UI Components**: shadcn/ui
- **State Management**: React Hooks
- **Testing**: Hardhat, Chai

## Smart Contracts

The platform is built on four main smart contracts:

1. **DepositETH (dETH)**: ERC20 token that users receive when depositing ETH
2. **StakedETH (sETH)**: ERC20 token that users receive when staking dETH
3. **Governance**: Handles proposal creation, voting, and execution
4. **StakingDashboard**: Provides statistics and leaderboard functionality

## Prerequisites

- Node.js 20.19.2 or 20.12.2 higher
- Metamask or another Ethereum wallet
- Access to Ethereum Sepolia testnet
- Private key for testing (with some test ETH)

## Installation

1. Install dependencies:
   ```bash
   npm run install:all
   ```

2. Set up environment variables:
   ```bash
   # Copy the example environment file
   cp .env.example .env
   
   # Edit .env and add your configuration:
   PRIVATE_KEY=your_private_key_here
   SEPOLIA_URL=your_sepolia_rpc_url
   STAKED_ETH_ADDRESS=deployed_staked_eth_contract_address
   DETH_ADDRESS=deployed_deth_contract_address
   ```

3. Run the development server:
   ```bash
   npm run dev
   ```

4. Open [http://localhost:3000] in your browser.

## Testing

### Smart Contract Testing

Run the smart contract tests using Hardhat:

```bash
npx hardhat test
```

This will run all tests in the `test/` directory, including:
- Staking functionality tests
- Unstaking functionality tests
- Staker tracking tests
- Contract integration tests

### API Testing

Once the development server is running, you can test the API endpoints:

#### 1. Stake ETH

Stake a specific amount of ETH:

```bash
curl --location 'http://localhost:4000/api/stake' \
--header 'Content-Type: application/json' \
--data '{"amount":"0.001"}'
```

**Expected Response:**
```json
{
    "success": true,
    "message": "Successfully staked 0.001 ETH",
    "txHash": "0xcdac6ef0fa545c0d09859bba926f088fa3545f6f2b80c439ac34ba98075a63bb"
}
```

#### 2. Get Staking Summary

Retrieve the total amount staked and number of stakers:

```bash
curl --location 'http://localhost:4000/api/anunayapitest'
```

**Expected Response:**
```json
{
    "success": true,
    "data": {
        "totalStaked": "2000000000000000",
        "totalStakers": "1"
    }
}
```

## API Endpoints

### POST /api/stake
Stakes ETH and returns the transaction hash.

**Request Body:**
```json
{
    "amount": "0.001"
}
```

**Response:**
```json
{
    "success": true,
    "message": "Successfully staked 0.001 ETH",
    "txHash": "0x..."
}
```

### GET /api/anunayapitest
Returns staking statistics.

**Response:**
```json
{
    "success": true,
    "data": {
        "totalStaked": "2000000000000000",
        "totalStakers": "1"
    }
}
```

## Project Structure

```
ethvault/
├── app/                  # Next.js app router pages
├── components/           # React components
│   ├── layout/           # Layout components
│   └── ui/               # UI components
├── contracts/            # Smart contract source code
├── hooks/                # Custom React hooks
├── lib/                  # Utility functions and ABIs
│   └── abis/             # Contract ABIs
├── public/               # Static assets
├── server/               # Backend API server
│   ├── controllers/      # API controllers
│   ├── routes/           # API routes
│   └── app.js           # Express app setup
├── styles/               # Global styles
├── test/                 # Smart contract tests
└── hardhat.config.js     # Hardhat configuration
```

## Environment Variables

Create a `.env` file in the root directory with the following variables:

```env
PRIVATE_KEY=your_ethereum_private_key
SEPOLIA_URL=your_sepolia_testnet_rpc_url
STAKED_ETH_ADDRESS=deployed_staked_eth_contract_address
DETH_ADDRESS=deployed_deth_contract_address
```

## Development Commands

- `npm run dev` - Start both frontend and backend servers
- `npm run backend` - Start only the backend server
- `npm run install:all` - Install dependencies for both frontend and backend
- `npx hardhat test` - Run smart contract tests
- `npx hardhat compile` - Compile smart contracts

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests for new functionality
5. Submit a pull request

## License

This project is licensed under the MIT License.
