use num_bigint::BigInt;
use ark_bn254::Fr;
use ark_ff::BigInteger256;
use num_traits::Num;

fn main() {
    // The string representation of the large integer
    let number_str = "9964141043217120936664326897183667118469716023855732146334024524079553329018";
    
    // Convert the string to a BigInt
    let bigint = BigInt::from_str_radix(number_str, 10).unwrap();

    // Convert BigInt to BigInteger256, which is the underlying representation used by Fr
    let bigint_bytes = bigint.to_bytes_be().1;
    let mut bytes_32 = vec![0_u8; 32];
    bytes_32[(32 - bigint_bytes.len())..].copy_from_slice(&bigint_bytes);

    let big_integer = BigInteger256::new([
        u64::from_be_bytes(bytes_32[24..32].try_into().unwrap()),
        u64::from_be_bytes(bytes_32[16..24].try_into().unwrap()),
        u64::from_be_bytes(bytes_32[8..16].try_into().unwrap()),
        u64::from_be_bytes(bytes_32[0..8].try_into().unwrap()),
    ]);

    // Convert BigInteger256 to Fr field element
    let fr_element = Fr::from(big_integer);

    // Output the result
    println!("Fr element: {:?}", fr_element);
}