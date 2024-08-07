function changeTextColor() {
    const content = document.getElementById("content");
    content.style.color = content.style.color === "black" ? "green" : "black";
}

function prove() {
    const a = document.getElementById("a").value;
    const b = document.getElementById("b").value;
    console.log(a, b);
}
