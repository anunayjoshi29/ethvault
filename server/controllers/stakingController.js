const { ethers } = require("ethers");
const path = require("path");
require("dotenv").config({ path: path.resolve(__dirname, "../../.env") });

// Load ABIs
const stakingAbi = require("../../artifacts/contracts/sETH.sol/StakedETH.json").abi;
const dEthAbi = require("../../artifacts/contracts/dETH.sol/DepositETH.json").abi;

// Contract addresses
const STAKED_ETH_ADDRESS = process.env.STAKED_ETH_ADDRESS;
const DETH_ADDRESS = process.env.DETH_ADDRESS;

// Provider and signer
const provider = new ethers.JsonRpcProvider(process.env.SEPOLIA_URL);
const signer = new ethers.Wallet(process.env.PRIVATE_KEY, provider);

// Contracts
const dEthContract = new ethers.Contract(DETH_ADDRESS, dEthAbi, signer);
const sEthContract = new ethers.Contract(STAKED_ETH_ADDRESS, stakingAbi, signer);
const sEthViewContract = new ethers.Contract(STAKED_ETH_ADDRESS, stakingAbi, provider); // for view-only

// GET /staking-summary
exports.getStakingSummary = async (req, res) => {
  try {
    const totalStaked = await sEthViewContract.totalStaked();
    const totalStakers = await sEthViewContract.totalStakers();

    return res.status(200).json({
      success: true,
      data: {
        totalStaked: totalStaked.toString(),
        totalStakers: totalStakers.toString(),
      },
    });
  } catch (error) {
    console.error("Error fetching contract data:", error);
    return res.status(500).json({
      success: false,
      message: "Failed to fetch data from StakedETH contract",
    });
  }
};

// POST /stake
exports.stakeETH = async (req, res) => {
  try {
    const amount = req.body.amount;
    const parsedAmount = ethers.parseEther(amount);

    // Step 1: Deposit ETH to get dETH
    const depositTx = await dEthContract.deposit({ value: parsedAmount });
    await depositTx.wait();

    // Step 2: Approve sETH contract to spend dETH
    const approveTx = await dEthContract.approve(STAKED_ETH_ADDRESS, parsedAmount);
    await approveTx.wait();

    // Step 3: Stake dETH to receive sETH
    const stakeTx = await sEthContract.stake(parsedAmount);
    await stakeTx.wait();

    res.status(200).json({
      success: true,
      message: `Successfully staked ${amount} ETH`,
      txHash: stakeTx.hash,
    });
  } catch (err) {
    console.error("Stake Error:", err);
    res.status(500).json({ success: false, error: err.message });
  }
};