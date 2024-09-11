// Original string
const rawbigIntString =
  "[BigInt([13216351313956316769, 5752703984264897570, 8550105013363225145, 3166028382212584833]), BigInt([2, 0, 0, 0]), BigInt([0, 0, 0, 0]), BigInt([0, 0, 0, 0]), BigInt([9062673722594577459, 18445398465162306915, 0, 0]), BigInt([9146102640559303075, 3173910318344653789, 0, 0]), BigInt([11010351400029728864, 8041655949790343150, 1, 0]), BigInt([16267416869269550474, 4771062823442508717, 5960020612943902980, 2867255844596557927]), BigInt([14432715788066016954, 13758632019443089827, 17367836913086241945, 2156809882891104188]), BigInt([22441747592080275, 0, 0, 0]), BigInt([27991402555270235, 0, 0, 0]), BigInt([25154490832722597, 0, 0, 0]), BigInt([10117472223630045, 0, 0, 0]), BigInt([8563020034, 0, 0, 0]), BigInt([5181076121304456, 0, 0, 0]), BigInt([12775384482183730, 0, 0, 0]), BigInt([17479939278674358, 0, 0, 0]), BigInt([4431758128409877, 0, 0, 0]), BigInt([6292057710, 0, 0, 0]), BigInt([34865969595464322, 0, 0, 0]), BigInt([25928778023626872, 0, 0, 0]), BigInt([4627451967773188, 0, 0, 0]), BigInt([1135112530259162, 0, 0, 0]), BigInt([2770841862, 0, 0, 0]), BigInt([20024085647366621, 0, 0, 0]), BigInt([414713443358314, 0, 0, 0]), BigInt([7635922378024960, 0, 0, 0]), BigInt([13116774268753812, 0, 0, 0]), BigInt([9401868148, 0, 0, 0]), BigInt([2820202543204788776, 587140582911657441, 11250490876538276031, 292734137026567018]), BigInt([10301528278074579267, 12833717586692649296, 1182640914584101134, 889363595041987920]), BigInt([484271084034449231, 3648294431596929542, 7732417564471753098, 3182880747302137707]), BigInt([15418200715277431906, 1526563225858806879, 8055455535386294221, 1436073284847493075]), BigInt([32877924356363047, 0, 0, 0]), BigInt([1710333993690865, 0, 0, 0]), BigInt([1025003307835604, 0, 0, 0]), BigInt([6831785905734038, 0, 0, 0]), BigInt([12456900840, 0, 0, 0]), BigInt([18347894549591896, 0, 0, 0]), BigInt([23347111856726962, 0, 0, 0]), BigInt([15297874506960138, 0, 0, 0]), BigInt([3228443586674254, 0, 0, 0]), BigInt([2657157532, 0, 0, 0]), BigInt([4286894517175236236, 18149755178807218953, 0, 0])]";

const bigIntString = rawbigIntString + ",";

const bigIntArray = bigIntString.split("BigInt(");
const prunedBigIntArray = bigIntArray.slice(1);
console.log(prunedBigIntArray);

// let publicInputArray = [BigInt(0)] * prunedBigIntArray.length;
let publicInputArray = new Array(prunedBigIntArray.length).fill(0n);

for (const [i, elt] of prunedBigIntArray.entries()) {
  const coeffs = elt.split(",").slice(0, -1);
  // console.log(coeffs);
  const cleanedCoeffs = coeffs.map((str) => str.replace(/[^\d]/g, ""));
  const bigintCoeffs = cleanedCoeffs.map((str) => BigInt(str));

  console.log(bigintCoeffs); // [15297874506960138, 0, 0]

  const base = 2n ** 64n; // 2^64
  let bigint = 0n;
  for (let i = 0; i < bigintCoeffs.length; i++) {
    bigint += bigintCoeffs[i] * base ** BigInt(i);
  }

  publicInputArray[i] = bigint.toString();
}

console.log("----------");
console.log("----------");
console.log("----------");
console.log("----------");
console.log(publicInputArray);
// // Convert BigInt notation to JSON-compatible format
// const jsonString = bigIntString
//   .replace(/BigInt\(/g, "[")
//   .replace(/\)/g, "]")
//   .replace(/n/g, ""); // Remove the 'n' suffix from BigInt literals

// // Parse the JSON string
// const jsonArray = JSON.parse(jsonString);

// console.log(jsonArray);
