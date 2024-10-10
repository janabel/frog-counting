export const ZUPASS_URL = "https://zupass.org";

export enum EmbeddedZupassState {
  CONNECTING,
  CONNECTED,
}

export const FrogCryptoPK =
  "0f183dcba06341a4549d78c3f8ca0060a9d6aca795103cb6957d1e2973b5fdeb"; // need to check that public key matches this, otherwise user can sign/issue their own Frog PODs
