import {
  time,
  loadFixture,
} from "@nomicfoundation/hardhat-toolbox/network-helpers";
import { anyValue } from "@nomicfoundation/hardhat-chai-matchers/withArgs";
import { expect } from "chai";
import hre from "hardhat";
import { HardhatEthersSigner } from "@nomicfoundation/hardhat-ethers/signers";

describe("Avatar", function () {
  // We define a fixture to reuse the same setup in every test.
  // We use loadFixture to run this setup once, snapshot that state,
  // and reset Hardhat Network to that snapshot in every test.
  async function deployOneYearLockFixture() {

    // Contracts are deployed using the first signer/account by default
    const [owner, otherAccount] = await hre.ethers.getSigners();
    
    const Avatar = await hre.ethers.getContractFactory("FarvilleAvatar");
    const avatar = await Avatar.deploy(
      owner.address,
      owner.address,
      owner.address,
      owner.address,
      owner.address,
      10,
      1000000,
      "test"
    );

    return { avatar, owner, otherAccount };
  }

  describe("Deployment", function () {
    it("Should set the right unlockTime", async function () {
      const { avatar, owner, otherAccount } = await loadFixture(deployOneYearLockFixture);

      expect(await avatar.owner()).to.equal(owner.address);
    });

  });
  describe("Mint", function () {
    it("Should mint the NFT", async function () {
      const { avatar, owner, otherAccount } = await loadFixture(deployOneYearLockFixture);

      const signature = await createMintSignature(owner, otherAccount.address, 1, "test");

      await avatar.connect(otherAccount).mint(otherAccount.address, 1, 1000000, "test", signature);

      expect(await avatar.ownerOf(1)).to.equal(otherAccount.address);
    });
    
  });

  async function createMintSignature(
    owner: HardhatEthersSigner,
    recipient: string,
    tokenId: number,
    tokenIdURI: string
) {
    // Pack the data the same way as the contract
    const messageHash = hre.ethers.solidityPackedKeccak256(
        ["address", "uint256", "string"],
        [recipient, tokenId, tokenIdURI]
    );

    // Sign the hash (this adds the "\x19Ethereum Signed Message:\n32" prefix)
    const signature = await owner.signMessage(hre.ethers.getBytes(messageHash));
    console.log(signature, "signature");
    
    return signature;
}
});
