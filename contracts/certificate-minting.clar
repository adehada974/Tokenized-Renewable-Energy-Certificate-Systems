;; Certificate Minting Contract
;; Creates tradeable energy credits based on verified generation

;; Constants
(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_UNAUTHORIZED (err u200))
(define-constant ERR_INVALID_AMOUNT (err u201))
(define-constant ERR_INSUFFICIENT_BALANCE (err u202))
(define-constant ERR_CERTIFICATE_EXISTS (err u203))
(define-constant ERR_INVALID_CERTIFICATE (err u204))
(define-constant ERR_ALREADY_RETIRED (err u205))

;; Fungible Token Definition
(define-fungible-token renewable-energy-certificate)

;; Data Variables
(define-data-var next-certificate-id uint u1)
(define-data-var total-certificates-minted uint u0)
(define-data-var total-certificates-retired uint u0)

;; Data Maps
(define-map certificates
  { certificate-id: uint }
  {
    owner: principal,
    energy-amount-kwh: uint,
    generation-source-id: uint,
    energy-type: (string-ascii 20),
    generation-date: uint,
    mint-date: uint,
    retired: bool,
    retirement-date: (optional uint),
    retirement-purpose: (optional (string-ascii 100)),
    metadata: (string-ascii 200)
  }
)

(define-map certificate-transfers
  { certificate-id: uint, transfer-id: uint }
  {
    from: principal,
    to: principal,
    timestamp: uint,
    transfer-type: (string-ascii 20)
  }
)

(define-map user-certificate-count
  { owner: principal }
  { count: uint, total-kwh: uint }
)

(define-map minter-permissions
  { minter: principal }
  { authorized: bool, granted-by: principal, granted-at: uint }
)

;; Authorization Functions
(define-private (is-contract-owner)
  (is-eq tx-sender CONTRACT_OWNER)
)

(define-private (is-authorized-minter (minter principal))
  (default-to false (get authorized (map-get? minter-permissions { minter: minter })))
)

;; Certificate Minting Functions
(define-public (mint-certificate
  (recipient principal)
  (energy-amount-kwh uint)
  (generation-source-id uint)
  (energy-type (string-ascii 20))
  (generation-date uint)
  (metadata (string-ascii 200)))
  (let
    (
      (certificate-id (var-get next-certificate-id))
      (token-amount energy-amount-kwh)
    )
    (asserts! (or (is-contract-owner) (is-authorized-minter tx-sender)) ERR_UNAUTHORIZED)
    (asserts! (> energy-amount-kwh u0) ERR_INVALID_AMOUNT)
    (asserts! (is-none (map-get? certificates { certificate-id: certificate-id })) ERR_CERTIFICATE_EXISTS)

    ;; Mint fungible tokens (1 kWh = 1 token)
    (try! (ft-mint? renewable-energy-certificate token-amount recipient))

    ;; Create certificate record
    (map-set certificates
      { certificate-id: certificate-id }
      {
        owner: recipient,
        energy-amount-kwh: energy-amount-kwh,
        generation-source-id: generation-source-id,
        energy-type: energy-type,
        generation-date: generation-date,
        mint-date: block-height,
        retired: false,
        retirement-date: none,
        retirement-purpose: none,
        metadata: metadata
      }
    )

    ;; Update user certificate count
    (let
      (
        (current-count (default-to { count: u0, total-kwh: u0 }
          (map-get? user-certificate-count { owner: recipient })))
      )
      (map-set user-certificate-count
        { owner: recipient }
        {
          count: (+ (get count current-count) u1),
          total-kwh: (+ (get total-kwh current-count) energy-amount-kwh)
        }
      )
    )

    ;; Update totals
    (var-set next-certificate-id (+ certificate-id u1))
    (var-set total-certificates-minted (+ (var-get total-certificates-minted) u1))

    (ok certificate-id)
  )
)

;; Certificate Transfer Functions
(define-public (transfer-certificate (certificate-id uint) (recipient principal))
  (let
    (
      (certificate (unwrap! (map-get? certificates { certificate-id: certificate-id }) ERR_INVALID_CERTIFICATE))
      (energy-amount (get energy-amount-kwh certificate))
    )
    (asserts! (is-eq tx-sender (get owner certificate)) ERR_UNAUTHORIZED)
    (asserts! (not (get retired certificate)) ERR_ALREADY_RETIRED)

    ;; Transfer fungible tokens
    (try! (ft-transfer? renewable-energy-certificate energy-amount tx-sender recipient))

    ;; Update certificate ownership
    (map-set certificates
      { certificate-id: certificate-id }
      (merge certificate { owner: recipient })
    )

    ;; Update sender count
    (let
      (
        (sender-count (default-to { count: u0, total-kwh: u0 }
          (map-get? user-certificate-count { owner: tx-sender })))
      )
      (map-set user-certificate-count
        { owner: tx-sender }
        {
          count: (- (get count sender-count) u1),
          total-kwh: (- (get total-kwh sender-count) energy-amount)
        }
      )
    )

    ;; Update recipient count
    (let
      (
        (recipient-count (default-to { count: u0, total-kwh: u0 }
          (map-get? user-certificate-count { owner: recipient })))
      )
      (map-set user-certificate-count
        { owner: recipient }
        {
          count: (+ (get count recipient-count) u1),
          total-kwh: (+ (get total-kwh recipient-count) energy-amount)
        }
      )
    )

    (ok true)
  )
)

;; Certificate Retirement Functions
(define-public (retire-certificate (certificate-id uint) (purpose (string-ascii 100)))
  (let
    (
      (certificate (unwrap! (map-get? certificates { certificate-id: certificate-id }) ERR_INVALID_CERTIFICATE))
      (energy-amount (get energy-amount-kwh certificate))
    )
    (asserts! (is-eq tx-sender (get owner certificate)) ERR_UNAUTHORIZED)
    (asserts! (not (get retired certificate)) ERR_ALREADY_RETIRED)

    ;; Burn fungible tokens
    (try! (ft-burn? renewable-energy-certificate energy-amount tx-sender))

    ;; Mark certificate as retired
    (map-set certificates
      { certificate-id: certificate-id }
      (merge certificate {
        retired: true,
        retirement-date: (some block-height),
        retirement-purpose: (some purpose)
      })
    )

    ;; Update user count
    (let
      (
        (user-count (default-to { count: u0, total-kwh: u0 }
          (map-get? user-certificate-count { owner: tx-sender })))
      )
      (map-set user-certificate-count
        { owner: tx-sender }
        {
          count: (- (get count user-count) u1),
          total-kwh: (- (get total-kwh user-count) energy-amount)
        }
      )
    )

    ;; Update total retired
    (var-set total-certificates-retired (+ (var-get total-certificates-retired) u1))

    (ok true)
  )
)

;; Minter Management
(define-public (grant-minter-permission (minter principal))
  (begin
    (asserts! (is-contract-owner) ERR_UNAUTHORIZED)
    (map-set minter-permissions
      { minter: minter }
      { authorized: true, granted-by: tx-sender, granted-at: block-height }
    )
    (ok true)
  )
)

(define-public (revoke-minter-permission (minter principal))
  (begin
    (asserts! (is-contract-owner) ERR_UNAUTHORIZED)
    (map-delete minter-permissions { minter: minter })
    (ok true)
  )
)

;; Read-only Functions
(define-read-only (get-certificate (certificate-id uint))
  (map-get? certificates { certificate-id: certificate-id })
)

(define-read-only (get-user-certificate-count (owner principal))
  (map-get? user-certificate-count { owner: owner })
)

(define-read-only (get-balance (owner principal))
  (ft-get-balance renewable-energy-certificate owner)
)

(define-read-only (get-total-supply)
  (ft-get-supply renewable-energy-certificate)
)

(define-read-only (get-certificate-stats)
  {
    total-minted: (var-get total-certificates-minted),
    total-retired: (var-get total-certificates-retired),
    active-certificates: (- (var-get total-certificates-minted) (var-get total-certificates-retired))
  }
)

(define-read-only (is-certificate-retired (certificate-id uint))
  (match (map-get? certificates { certificate-id: certificate-id })
    certificate (get retired certificate)
    false
  )
)

(define-read-only (get-next-certificate-id)
  (var-get next-certificate-id)
)
