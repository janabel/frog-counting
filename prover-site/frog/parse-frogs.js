const fs = require('fs');
const assert = require('assert');

console.log(process.cwd())

// const jsonString = fs.readFileSync('frog formatting/test.json', 'utf8');
const jsonString = fs.readFileSync('frog formatting/frogs-dump.txt', 'utf8');
// console.log(jsonString)

const jsonObject = JSON.parse(jsonString);
console.log(typeof jsonObject)
console.log(jsonObject[0].type)

jsonObject.forEach((frog_data, i) => {
    assert.strictEqual(frog_data.type, "eddsa-frog-pcd")
    // console.log("hi")
    frog_pcd = frog_data.pcd
    frog_json = JSON.parse(frog_pcd)
    console.log(frog_json, frog_json.id)
    eddsa_pcd = frog_json.eddsaPCD
    pcd_json = JSON.parse(eddsa_pcd.pcd)
    console.log(pcd_json)
});

// const outputJsonString = JSON.stringify(jsonObject, null, 2);

// console.log(typeof outputJsonString)
// console.log(outputJsonString)

// // fs.writeFileSync('output.json', outputJsonString, 'utf8');

// // console.log('JSON data has been saved to output.json');
