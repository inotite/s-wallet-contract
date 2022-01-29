import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { expect } from "chai";
import { BigNumber } from "ethers";
import { ethers } from "hardhat";
import { SimpleWallet } from "typechain";

describe("SimpleWallet", () => {
  let wallet: SimpleWallet;
  let owner: SignerWithAddress;
  let notAllowedUser: SignerWithAddress;
  let allowedUser: SignerWithAddress;
  let generalUser: SignerWithAddress;

  beforeEach(async () => {
    const SimpleWallet = await ethers.getContractFactory("SimpleWallet");
    const contractInstance = await SimpleWallet.deploy();
    wallet = await contractInstance.deployed();
    [owner, notAllowedUser, allowedUser, generalUser] =
      await ethers.getSigners();
    await expect(
      wallet.signer.sendTransaction({
        to: wallet.address,
        value: BigNumber.from("1000000000000000000"),
      })
    )
      .to.emit(wallet, "MoneyReceived")
      .withArgs(owner.address, "1000000000000000000");
  });

  const getContractBalance = () => wallet.provider.getBalance(wallet.address);

  describe("withdrawMoney()", () => {
    it("should withdraw money", async () => {
      const originalBalance: BigNumber = await getContractBalance();
      await expect(wallet.withdrawMoney(generalUser.address, 1e10))
        .to.emit(wallet, "MoneySent")
        .withArgs(generalUser.address, 1e10);
      const currentBalance: BigNumber = await getContractBalance();
      expect(originalBalance).to.eq(currentBalance.add(1e10));
    });

    it("should throw error if the msg sender is not the owner and allowance is smaller than the amount", async () => {
      await expect(
        wallet.connect(notAllowedUser).withdrawMoney(generalUser.address, 1e10)
      ).to.be.revertedWith("You are not allowed");
    });

    it("should throw error if contract doesn't have enough funds", async () => {
      await expect(
        wallet.withdrawMoney(
          generalUser.address,
          BigNumber.from("10000000000000000000")
        )
      ).to.be.revertedWith("not enough funds");
    });

    it("should withdraw money if the msg sender is allowed", async () => {
      await wallet.addAllowance(allowedUser.address, 1e5);
      const originalAllowance = await wallet.allowance(allowedUser.address);
      await expect(
        wallet.connect(allowedUser).withdrawMoney(generalUser.address, 1e4)
      )
        .to.emit(wallet, "AllowanceChanged")
        .withArgs(allowedUser.address, allowedUser.address, 1e5, 9e4)
        .to.emit(wallet, "MoneySent")
        .withArgs(generalUser.address, 1e4);
      const allowance = await wallet.allowance(allowedUser.address);
      expect(originalAllowance).to.eq(allowance.add(1e4));
    });
  });

  describe("addAllowance()", () => {
    it("should not allow general users", async () => {
      await expect(
        wallet.connect(generalUser).addAllowance(allowedUser.address, 1e5)
      ).to.be.revertedWith("Ownable: caller is not the owner");
    });

    it("should emit 'AllwanceChanged' event if the method is called", async () => {
      await expect(wallet.addAllowance(allowedUser.address, 1e5))
        .to.emit(wallet, "AllowanceChanged")
        .withArgs(allowedUser.address, owner.address, 0, 1e5);
    });
  });

  describe("renounceOwnership()", () => {
    it("should be reverted", async () => {
      await expect(wallet.renounceOwnership()).to.be.revertedWith(
        "Can't renounce ownership here"
      );
    });
  });
});
