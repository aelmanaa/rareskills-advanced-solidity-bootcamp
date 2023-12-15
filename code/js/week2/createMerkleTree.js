import { StandardMerkleTree } from "@openzeppelin/merkle-tree";
import fs from "fs";

// (1)
// 998 NFTs to distribute in total
const values = [
  ["0x0000000000000000000000000000000000000001", "0", "10"],
  ["0x0000000000000000000000000000000000000002", "1", "100"],
  ["0x0000000000000000000000000000000000000003", "2", "40"],
  ["0x0000000000000000000000000000000000000004", "3", "50"],
  ["0x0000000000000000000000000000000000000005", "4", "200"],
  ["0x0000000000000000000000000000000000000006", "5", "145"],
  ["0x0000000000000000000000000000000000000007", "6", "431"],
  ["0x0000000000000000000000000000000000000008", "7", "22"],
];

// (2) - receiver , index , number of tokens
const tree = StandardMerkleTree.of(values, ["address", "uint256", "uint256"]);

// (3)
console.log("Merkle Root:", tree.root);

// (4)
fs.writeFileSync("tree.json", JSON.stringify(tree.dump()));
