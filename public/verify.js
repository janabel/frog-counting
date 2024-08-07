const snarkjs = require("snarkjs");
const path = require("path");
const vkeyPath = require("./multiplier_vkey.json");
// const publicPath = "./public.json";
const axios = require("axios").default;

document
  .getElementById("verify-proof-button")
  .addEventListener("click", async function () {
    const rawProof = document.getElementById("proof").value;
    const proof = JSON.parse(rawProof);
    // console.log(proof);

    const vkey = require("./multiplier_vkey.json");
    console.log(vkey);
    const public = require("./public.json");
    console.log(public);
  });
