;; Institution Verification Contract
;; Validates and manages financial entities in the decentralized market

(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_UNAUTHORIZED (err u100))
(define-constant ERR_ALREADY_VERIFIED (err u101))
(define-constant ERR_NOT_FOUND (err u102))
(define-constant ERR_INVALID_STATUS (err u103))

;; Institution status types
(define-constant STATUS_PENDING u0)
(define-constant STATUS_VERIFIED u1)
(define-constant STATUS_SUSPENDED u2)
(define-constant STATUS_REVOKED u3)

;; Data structures
(define-map institutions
  { institution-id: principal }
  {
    name: (string-ascii 100),
    institution-type: (string-ascii 50),
    status: uint,
    verification-date: uint,
    verifier: principal
  }
)

(define-map institution-permissions
  { institution-id: principal }
  {
    can-trade: bool,
    can-settle: bool,
    can-clear: bool,
    risk-limit: uint
  }
)

(define-data-var next-institution-id uint u1)

;; Public functions
(define-public (register-institution (name (string-ascii 100)) (institution-type (string-ascii 50)))
  (let ((institution-id tx-sender))
    (asserts! (is-none (map-get? institutions { institution-id: institution-id })) ERR_ALREADY_VERIFIED)
    (map-set institutions
      { institution-id: institution-id }
      {
        name: name,
        institution-type: institution-type,
        status: STATUS_PENDING,
        verification-date: block-height,
        verifier: CONTRACT_OWNER
      }
    )
    (ok institution-id)
  )
)

(define-public (verify-institution (institution-id principal))
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (match (map-get? institutions { institution-id: institution-id })
      institution-data
      (begin
        (map-set institutions
          { institution-id: institution-id }
          (merge institution-data { status: STATUS_VERIFIED, verification-date: block-height })
        )
        (map-set institution-permissions
          { institution-id: institution-id }
          {
            can-trade: true,
            can-settle: true,
            can-clear: true,
            risk-limit: u1000000
          }
        )
        (ok true)
      )
      ERR_NOT_FOUND
    )
  )
)

(define-public (suspend-institution (institution-id principal))
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (match (map-get? institutions { institution-id: institution-id })
      institution-data
      (begin
        (map-set institutions
          { institution-id: institution-id }
          (merge institution-data { status: STATUS_SUSPENDED })
        )
        (ok true)
      )
      ERR_NOT_FOUND
    )
  )
)

;; Read-only functions
(define-read-only (get-institution (institution-id principal))
  (map-get? institutions { institution-id: institution-id })
)

(define-read-only (get-institution-permissions (institution-id principal))
  (map-get? institution-permissions { institution-id: institution-id })
)

(define-read-only (is-verified (institution-id principal))
  (match (map-get? institutions { institution-id: institution-id })
    institution-data
    (is-eq (get status institution-data) STATUS_VERIFIED)
    false
  )
)
