// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.26;

/*
    Some people are very keen on saving on transactions wherever possible, 
    like this enthusiast who decided to create a new WETH contract where all 
    functionality is implemented with Yul inserts. It's more economical, 
    no doubt, but has this contract undergone an audit?
    Your task is to withdraw all funds from the contract, starting with 15 ether.
*/

contract CheaperWETH {
    string public name     = "Wrapped Ether";
    string public symbol   = "WETH";
    uint8  public decimals = 18;

    event  Approval(address indexed src, address indexed guy, uint wad);
    event  Transfer(address indexed src, address indexed dst, uint wad);
    event  Deposit(address indexed dst, uint wad);
    event  Withdrawal(address indexed src, uint wad);

    mapping (address => uint)                       public  balanceOf;
    mapping (address => mapping (address => uint))  public  allowance;

    receive() external payable {
        deposit();
    }

    function deposit() public payable {
        assembly {
            mstore(0x00, caller())
            mstore(0x20, balanceOf.slot)

            let slot := keccak256(0x00, 0x40)

            let currentBalance := sload(slot)

            let newBalance := add(currentBalance, callvalue())

            sstore(slot, newBalance)
        }
    }

    function withdraw(uint wad) public {
        assembly {
            mstore(0x00, caller())
            mstore(0x20, balanceOf.slot)

            let slot := keccak256(0x00, 0x40)
            let currentBalance := sload(slot)

            if lt(sub(currentBalance, wad), 0) {
                revert(0, 0)
            }

            let newBalance := sub(currentBalance, wad)
            sstore(slot, newBalance)

            let success := call(gas(), caller(), wad, 0, 0, 0, 0)

            if iszero(success) {
                revert(0, 0)
            }
        }
    }

    function totalSupply() public view returns (uint supply) {
        assembly {
            supply := selfbalance()
        }
    }

    function approve(address guy, uint wad) public returns (bool success) {
        assembly {
            mstore(0x00, caller())
            mstore(0x20, allowance.slot)
            let slot := keccak256(0x00, 0x40)

            mstore(0x00, guy)
            mstore(0x20, slot)
            slot := keccak256(0x00, 0x40)

            sstore(slot, wad)

            success := true
        }
    }

    function transfer(address dst, uint wad) public returns (bool) {
        return transferFrom(msg.sender, dst, wad);
    }

    function transferFrom(address src, address dst, uint wad)
        public
        returns (bool success)
    {
        assembly {
            mstore(0x00, src)
            mstore(0x20, balanceOf.slot)
            let srcBalanceSlot := keccak256(0x00, 0x40)
            let srcBalance := sload(srcBalanceSlot)

            if lt(srcBalance, wad) {
                revert(0, 0)
            }

            if iszero(eq(src, caller())) {
                mstore(0x00, src)
                mstore(0x20, allowance.slot)
                let allowanceSlot := keccak256(0x00, 0x40)

                mstore(0x00, caller())
                mstore(0x20, allowanceSlot)
                allowanceSlot := keccak256(0x00, 0x40)

                let allowed := sload(allowanceSlot)

                if lt(allowed, wad) {
                    revert(0, 0)
                }

                sstore(allowanceSlot, sub(allowed, wad))
            }

            let newSrcBalance := sub(srcBalance, wad)
            sstore(srcBalanceSlot, newSrcBalance)

            mstore(0x00, dst)
            mstore(0x20, balanceOf.slot)
            let dstBalanceSlot := keccak256(0x00, 0x40)
            let dstBalance := sload(dstBalanceSlot)

            let newDstBalance := add(dstBalance, wad)
            sstore(dstBalanceSlot, newDstBalance)

            success := true
        }
    }
}
