#[cfg(test)]
pub(crate) mod tests {
    use ark_ff::{BigInteger, BigInteger256, PrimeField};
    use folding_schemes::Error;

    /// interprets the vector of finite field elements as a vector of bytes
    pub(crate) fn f_vec_to_bytes<F: PrimeField>(b: Vec<F>) -> Vec<u8> {
        b.iter()
            .map(|e| {
                let bytes: Vec<u8> = e.into_bigint().to_bytes_le();
                bytes[0]
            })
            .collect()
    }
    /// for a given byte array, returns the bytes representation in finite field elements
    pub(crate) fn bytes_to_f_vec<F: PrimeField>(b: Vec<u8>) -> Result<Vec<F>, Error> {
        Ok(b.iter()
            .map(|&e| F::from_le_bytes_mod_order(&[e]))
            .collect::<Vec<F>>())
    }
    /// returns the bytes representation of the given vector of finite field elements that represent
    /// bits
    pub(crate) fn f_vec_bits_to_bytes<F: PrimeField>(v: Vec<F>) -> Vec<u8> {
        let b = f_vec_to_bits(v);
        BigInteger256::from_bits_le(&b).to_bytes_le()
    }
    /// for a given byte array, returns its bits representation in finite field elements
    pub(crate) fn bytes_to_f_vec_bits<F: PrimeField>(b: Vec<u8>) -> Result<Vec<F>, Error> {
        use num_bigint::BigUint;
        let bi = BigUint::from_bytes_le(&b);
        let bi = BigInteger256::try_from(bi).unwrap();
        let bits = bi.to_bits_le();
        Ok(bits
            .iter()
            .map(|&e| if e { F::one() } else { F::zero() })
            .collect())
    }
    /// interprets the given vector of finite field elements as a vector of bits
    pub(crate) fn f_vec_to_bits<F: PrimeField>(v: Vec<F>) -> Vec<bool> {
        v.iter()
            .map(|v_i| {
                if v_i.is_one() {
                    return true;
                }
                false
            })
            .collect()
    }
}
