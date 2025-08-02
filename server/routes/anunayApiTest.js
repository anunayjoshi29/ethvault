const express = require("express");
const { getStakingSummary } = require("../controllers/stakingController");
const { stakeETH } = require("../controllers/stakingController");

const router = express.Router();

router.route("/anunayapitest").get(getStakingSummary);
router.route("/stake").post(stakeETH);

module.exports = router;
