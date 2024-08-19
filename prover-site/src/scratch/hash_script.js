async function generateHash(input) {
    const encoder = new TextEncoder();
    const data = encoder.encode(input);
    const hashBuffer = await crypto.subtle.digest('SHA-256', data);
    const hashArray = Array.from(new Uint8Array(hashBuffer));
    const hashHex = hashArray.map(b => b.toString(16).padStart(2, '0')).join('');
    return hashHex;
}

document.getElementById('hashButton').addEventListener('click', async () => {
    const userInput = document.getElementById('userInput').value;
    if (userInput) {
        const hash = await generateHash(userInput);
        document.getElementById('output').value = hash;
    } else {
        document.getElementById('output').value = 'Please enter a string to hash.';
    }
});
