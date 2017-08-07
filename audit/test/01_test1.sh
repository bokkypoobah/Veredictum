#!/bin/bash
# ----------------------------------------------------------------------------------------------
# Testing the smart contract
#
# Enjoy. (c) BokkyPooBah / Bok Consulting Pty Ltd 2017. The MIT Licence.
# ----------------------------------------------------------------------------------------------

MODE=${1:-test}

GETHATTACHPOINT=`grep ^IPCFILE= settings.txt | sed "s/^.*=//"`
PASSWORD=`grep ^PASSWORD= settings.txt | sed "s/^.*=//"`

CONTRACTSDIR=`grep ^CONTRACTSDIR= settings.txt | sed "s/^.*=//"`

TOKENSOL=`grep ^TOKENSOL= settings.txt | sed "s/^.*=//"`
TOKENTEMPSOL=`grep ^TOKENTEMPSOL= settings.txt | sed "s/^.*=//"`
TOKENJS=`grep ^TOKENJS= settings.txt | sed "s/^.*=//"`

DEPLOYMENTDATA=`grep ^DEPLOYMENTDATA= settings.txt | sed "s/^.*=//"`

INCLUDEJS=`grep ^INCLUDEJS= settings.txt | sed "s/^.*=//"`
TEST1OUTPUT=`grep ^TEST1OUTPUT= settings.txt | sed "s/^.*=//"`
TEST1RESULTS=`grep ^TEST1RESULTS= settings.txt | sed "s/^.*=//"`

CURRENTTIME=`date +%s`
CURRENTTIMES=`date -r $CURRENTTIME -u`

BLOCKSINDAY=10

if [ "$MODE" == "dev" ]; then
  # Start time now
  STARTTIME=`echo "$CURRENTTIME" | bc`
else
  # Start time 1m 10s in the future
  STARTTIME=`echo "$CURRENTTIME+30" | bc`
fi
STARTTIME_S=`date -r $STARTTIME -u`
ENDTIME=`echo "$CURRENTTIME+60*3" | bc`
ENDTIME_S=`date -r $ENDTIME -u`

printf "MODE            = '$MODE'\n" | tee $TEST1OUTPUT
printf "GETHATTACHPOINT = '$GETHATTACHPOINT'\n" | tee -a $TEST1OUTPUT
printf "PASSWORD        = '$PASSWORD'\n" | tee -a $TEST1OUTPUT
printf "CONTRACTSDIR    = '$CONTRACTSDIR'\n" | tee -a $TEST1OUTPUT
printf "TOKENSOL        = '$TOKENSOL'\n" | tee -a $TEST1OUTPUT
printf "TOKENTEMPSOL    = '$TOKENTEMPSOL'\n" | tee -a $TEST1OUTPUT
printf "TOKENJS         = '$TOKENJS'\n" | tee -a $TEST1OUTPUT
printf "DEPLOYMENTDATA  = '$DEPLOYMENTDATA'\n" | tee -a $TEST1OUTPUT
printf "INCLUDEJS       = '$INCLUDEJS'\n" | tee -a $TEST1OUTPUT
printf "TEST1OUTPUT     = '$TEST1OUTPUT'\n" | tee -a $TEST1OUTPUT
printf "TEST1RESULTS    = '$TEST1RESULTS'\n" | tee -a $TEST1OUTPUT
printf "CURRENTTIME     = '$CURRENTTIME' '$CURRENTTIMES'\n" | tee -a $TEST1OUTPUT
printf "STARTTIME       = '$STARTTIME' '$STARTTIME_S'\n" | tee -a $TEST1OUTPUT
printf "ENDTIME         = '$ENDTIME' '$ENDTIME_S'\n" | tee -a $TEST1OUTPUT

# Make copy of SOL file and modify start and end times ---
`cp $CONTRACTSDIR/$TOKENSOL $TOKENTEMPSOL`

# --- Modify parameters ---
`perl -pi -e "s/FUND_WALLET     \= 0x0;/FUND_WALLET     \= 0xa22AB8A9D641CE77e06D98b7D7065d324D3d6976;/" $TOKENTEMPSOL`
`perl -pi -e "s/START_DATE      \= 1502668800;.*$/START_DATE      = $STARTTIME; \/\/ $STARTTIME_S/" $TOKENTEMPSOL`
`perl -pi -e "s/END_DATE  \= START_DATE \+ FUNDING_PERIOD;.*$/END_DATE  \= $ENDTIME; \/\/ $ENDTIME_S/" $TOKENTEMPSOL`
`perl -pi -e "s/USD_PER_ETH     \= 0;.*$/USD_PER_ETH     \= 270;/" $TOKENTEMPSOL`

DIFFS1=`diff $CONTRACTSDIR/$TOKENSOL $TOKENTEMPSOL`
echo "--- Differences $CONTRACTSDIR/$TOKENSOL $TOKENTEMPSOL ---"
echo "$DIFFS1"

echo "var tokenOutput=`solc --optimize --combined-json abi,bin,interface $TOKENTEMPSOL`;" > $TOKENJS

geth --verbosity 3 attach $GETHATTACHPOINT << EOF | tee -a $TEST1OUTPUT
loadScript("$TOKENJS");
loadScript("functions.js");

var tokenAbi = JSON.parse(tokenOutput.contracts["$TOKENTEMPSOL:VentanaToken"].abi);
var tokenBin = "0x" + tokenOutput.contracts["$TOKENTEMPSOL:VentanaToken"].bin;

console.log("DATA: tokenAbi=" + JSON.stringify(tokenAbi));

unlockAccounts("$PASSWORD");
printBalances();
console.log("RESULT: ");


// -----------------------------------------------------------------------------
var deployTokenMessage = "Deploy Token Contract";
// -----------------------------------------------------------------------------
console.log("RESULT: " + deployTokenMessage);
var tokenContract = web3.eth.contract(tokenAbi);
console.log(JSON.stringify(tokenContract));
var tokenTx = null;
var tokenAddress = null;

var token = tokenContract.new({from: contractOwnerAccount, data: tokenBin, gas: 6000000},
  function(e, contract) {
    if (!e) {
      if (!contract.address) {
        tokenTx = contract.transactionHash;
      } else {
        tokenAddress = contract.address;
        console.log("RESULT: tokenAddress=" + tokenAddress);
        console.log("RESULT: token.symbol()=" + token.symbol());
        // TODO console.log("RESULT: token.name()=" + token.name());
        addAccount(tokenAddress, "Token '" + token.symbol() + "'");
        addTokenContractAddressAndAbi(tokenAddress, tokenAbi);
        console.log("DATA: tokenAddress=" + tokenAddress);
      }
    }
  }
);

while (txpool.status.pending > 0) {
}

printTxData("tokenAddress=" + tokenAddress, tokenTx);
printBalances();
failIfGasEqualsGasUsed(tokenTx, deployTokenMessage);
printTokenContractDetails();
console.log("RESULT: ");


// -----------------------------------------------------------------------------
var addKycAccountsMessage = "Add KYC Accounts";
// -----------------------------------------------------------------------------
console.log("RESULT: " + addKycAccountsMessage);
var addKycAccounts1Tx = token.addKycAddress(account5, true, {from: contractOwnerAccount, to: tokenAddress, gas: 400000});
var addKycAccounts2Tx = token.addKycAddress(account6, true, {from: contractOwnerAccount, to: tokenAddress, gas: 400000});
while (txpool.status.pending > 0) {
}
printTxData("addKycAccounts1Tx", addKycAccounts1Tx);
printTxData("addKycAccounts2Tx", addKycAccounts2Tx);
printBalances();
failIfGasEqualsGasUsed(addKycAccounts1Tx, addKycAccountsMessage + " ac5 true");
failIfGasEqualsGasUsed(addKycAccounts2Tx, addKycAccountsMessage + " ac6 true");
printTokenContractDetails();
console.log("RESULT: ");


// -----------------------------------------------------------------------------
// Wait for crowdsale start
// -----------------------------------------------------------------------------
var startTime = token.START_DATE();
var startTimeDate = new Date(startTime * 1000);
console.log("RESULT: Waiting until startTime at " + startTime + " " + startTimeDate +
  " currentDate=" + new Date());
while ((new Date()).getTime() <= startTimeDate.getTime()) {
}
console.log("RESULT: Waited until startTime at " + startTime + " " + startTimeDate +
  " currentDate=" + new Date());


// -----------------------------------------------------------------------------
var validContribution1Message = "Send Valid Contribution";
// -----------------------------------------------------------------------------
console.log("RESULT: " + validContribution1Message);
var sendValidContribution1Tx = eth.sendTransaction({from: account5, to: tokenAddress, gas: 400000, value: web3.toWei("1000.123333333333333333", "ether")});
var sendValidContribution2Tx = eth.sendTransaction({from: account6, to: tokenAddress, gas: 400000, value: web3.toWei("7000.234444444444444444", "ether")});
while (txpool.status.pending > 0) {
}
printTxData("sendValidContribution1Tx", sendValidContribution1Tx);
printTxData("sendValidContribution2Tx", sendValidContribution2Tx);
printBalances();
failIfGasEqualsGasUsed(sendValidContribution1Tx, validContribution1Message + " 1000.x ETH from ac5");
failIfGasEqualsGasUsed(sendValidContribution2Tx, validContribution1Message + " 7000.x ETH from ac6");
printTokenContractDetails();
console.log("RESULT: ");


// -----------------------------------------------------------------------------
var finaliseMessage = "Finalise Crowdsale";
// -----------------------------------------------------------------------------
console.log("RESULT: " + finaliseMessage);
var finaliseTx = token.finaliseICO({from: contractOwnerAccount, to: tokenAddress, gas: 400000});
while (txpool.status.pending > 0) {
}
printTxData("finaliseTx", finaliseTx);
printBalances();
failIfGasEqualsGasUsed(finaliseTx, finaliseMessage);
printTokenContractDetails();
console.log("RESULT: ");


exit;


// -----------------------------------------------------------------------------
var preCommitMessage = "Add PreCommitments - 1000 BET Acc3, 10000 BET Acc4";
console.log("RESULT: " + preCommitMessage);
var preCommit1Tx = dct.addPrecommitment(preCommitAccount1, "1000000000000000000000", {from: contractOwnerAccount, gas: 400000});
var preCommit2Tx = dct.addPrecommitment(preCommitAccount2, "10000000000000000000000", {from: contractOwnerAccount, gas: 400000});
while (txpool.status.pending > 0) {
}
printTxData("preCommit1Tx", preCommit1Tx);
printTxData("preCommit2Tx", preCommit2Tx);
printBalances();
failIfGasEqualsGasUsed(preCommit1Tx, preCommitMessage);
failIfGasEqualsGasUsed(preCommit2Tx, preCommitMessage);
printDctContractDetails();
console.log("RESULT: ");


// -----------------------------------------------------------------------------
var cannotTransferMessage = "Cannot Move Tokens Without Finalisation";
console.log("RESULT: " + cannotTransferMessage);
var cannotTransfer1Tx = dct.transfer(account7, "1000000000000", {from: account5, gas: 100000});
var cannotTransfer2Tx = dct.approve(account8,  "30000000000000000", {from: account6, gas: 100000});
while (txpool.status.pending > 0) {
}
var cannotTransfer3Tx = dct.transferFrom(account6, account8, "30000000000000000", {from: account8, gas: 100000});
while (txpool.status.pending > 0) {
}
printTxData("cannotTransfer1Tx", cannotTransfer1Tx);
printTxData("cannotTransfer2Tx", cannotTransfer2Tx);
printTxData("cannotTransfer3Tx", cannotTransfer3Tx);
printBalances();
passIfGasEqualsGasUsed(cannotTransfer1Tx, cannotTransferMessage + " - transfer 0.000001 BET ac5 -> ac7. CHECK no movement");
failIfGasEqualsGasUsed(cannotTransfer2Tx, cannotTransferMessage + " - approve 0.03 BET ac6 -> ac8");
passIfGasEqualsGasUsed(cannotTransfer3Tx, cannotTransferMessage + " - transferFrom 0.03 BET ac6 -> ac8. CHECK no movement");
printDctContractDetails();
console.log("RESULT: ");


// -----------------------------------------------------------------------------
var validContribution2Message = "Send Valid Contribution - 79 ETH From Account5";
console.log("RESULT: " + validContribution2Message);
var sendValidContribution3Tx = eth.sendTransaction({from: account5, to: dctAddress, gas: 400000, value: web3.toWei("79", "ether")});
while (txpool.status.pending > 0) {
}
printTxData("sendValidContribution3Tx", sendValidContribution3Tx);
printBalances();
failIfGasEqualsGasUsed(sendValidContribution3Tx, validContribution2Message);
printDctContractDetails();
console.log("RESULT: ");


// -----------------------------------------------------------------------------
var invalidContribution3Message = "Send Invalid Contribution - 1 ETH From Account7 - Cap Reached";
console.log("RESULT: " + invalidContribution3Message);
var sendInvalidContribution1Tx = eth.sendTransaction({from: account7, to: dctAddress, gas: 400000, value: web3.toWei("1", "ether")});
while (txpool.status.pending > 0) {
}
printTxData("sendInvalidContribution1Tx", sendInvalidContribution1Tx);
printBalances();
passIfGasEqualsGasUsed(sendInvalidContribution1Tx, invalidContribution3Message);
printDctContractDetails();
console.log("RESULT: ");


// -----------------------------------------------------------------------------
var canTransferMessage = "Can Move Tokens After Cap Reached";
console.log("RESULT: " + canTransferMessage);
var canTransfer1Tx = dct.transfer(account7, "1000000000000", {from: account5, gas: 100000});
var canTransfer2Tx = dct.approve(account8,  "30000000000000000", {from: account6, gas: 100000});
while (txpool.status.pending > 0) {
}
var canTransfer3Tx = dct.transferFrom(account6, account8, "30000000000000000", {from: account8, gas: 100000});
while (txpool.status.pending > 0) {
}
printTxData("canTransfer1Tx", canTransfer1Tx);
printTxData("canTransfer2Tx", canTransfer2Tx);
printTxData("canTransfer3Tx", canTransfer3Tx);
printBalances();
failIfGasEqualsGasUsed(canTransfer1Tx, canTransferMessage + " - transfer 0.000001 BET ac5 -> ac7. CHECK for movement");
failIfGasEqualsGasUsed(canTransfer2Tx, canTransferMessage + " - approve 0.03 BET ac6 -> ac8");
failIfGasEqualsGasUsed(canTransfer3Tx, canTransferMessage + " - transferFrom 0.03 BET ac6 -> ac8. CHECK for movement");
printDctContractDetails();
console.log("RESULT: ");

EOF
grep "DATA: " $TEST1OUTPUT | sed "s/DATA: //" > $DEPLOYMENTDATA
cat $DEPLOYMENTDATA
grep "RESULT: " $TEST1OUTPUT | sed "s/RESULT: //" > $TEST1RESULTS
cat $TEST1RESULTS
