-include .env

.PHONY: all test clean deploy fund help install snapshot format anvil scopefile halmos cloc

DEFAULT_ANVIL_KEY := 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80

all: remove install build

# Clean the repo
clean  :; forge clean

# Remove modules
remove :; rm -rf .gitmodules && rm -rf .git/modules/* && rm -rf lib && touch .gitmodules 

install :; forge install foundry-rs/forge-std --no-commit && forge install openzeppelin/openzeppelin-contracts --no-commit && forge install a16z/halmos-cheatcodes --no-commit && forge install huff-language/foundry-huff --no-commit

# Update Dependencies
update:; forge update

build:; RUST_LOG=debug forge build

zkbuild :; RUST_LOG=debug forge build --zksync

test :; forge test

zktest :; forge test --zksync 

# I couldn't get the --match-contract to work
# REMEMBER, WE MANUALLY ADD THE HUFF CODE TO OUR FormalEquivalence.sol FILE
# huffc src/protocol/TSender.huff --bytecode > compiled_huff.txt
halmos :; halmos --function testEachShouldSendTheExactAmount --solver-timeout-assertion 0 && halmos --function testBothRevertIfValueIsSent --solver-timeout-assertion 0 && halmos --function testAreListsValidAlwaysOutputEquallyForSolcAndYul --solver-timeout-assertion 0 && halmos --function testSolidInputsResultInTheSameOutputsFuzz --solver-timeout-assertion 0

snapshot :; forge snapshot

format :; forge fmt

anvil :; anvil -m 'test test test test test test test test test test test junk' --steps-tracing --block-time 1

slither :; slither . --config-file slither.config.json

aderyn :; aderyn .

scopefile :; @tree ./src/ | sed 's/└/#/g' | awk -F '── ' '!/\.sol$$/ { path[int((length($$0) - length($$2))/2)] = $$2; next } { p = "src"; for(i=2; i<=int((length($$0) - length($$2))/2); i++) if (path[i] != "") p = p "/" path[i]; print p "/" $$2; }' > scope.txt

scope :; tree ./src/ | sed 's/└/#/g; s/──/--/g; s/├/#/g; s/│ /|/g; s/│/|/g'

deployyul :; forge script script/DeployYul.s.sol --rpc-url ${RPC_URL} --account ${ACCOUNT} --sender ${SENDER} --broadcast --verify -vvvv

deployhuff :; forge script script/DeployHuff.s.sol --rpc-url ${RPC_URL} --account ${ACCOUNT} --sender ${SENDER} --broadcast --verify -vvvv

cloc :; cloc --force-lang="javascript",huff src/protocol/TSender.huff  && cloc --force-lang="javascript",huff src/protocol/TSender_NoCheck.huff && cloc ./src/protocol/TSender.sol