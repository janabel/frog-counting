const prover = require("../prover.js");

function changeTextColor() {
    const content = document.getElementById("content");
    content.style.color = content.style.color === "black" ? "green" : "black";
}

function prove() {
    const a_char = document.getElementById("a").value;
    const b_char = document.getElementById("b").value;
    const a = parseInt(a_char);
    const b = parseInt(b_char);
    
    const witness = prover.generateWitness(a, b);
    console.log(witness);
}
