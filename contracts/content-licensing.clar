;; Content Licensing Contract

;; Define data structures
(define-map content-licenses
  { content-id: uint }
  {
    owner: principal,
    title: (string-ascii 256),
    license-type: (string-ascii 64),
    expiration: uint,
    price: uint
  }
)

(define-map user-licenses
  { user: principal, content-id: uint }
  { expiration: uint }
)

(define-data-var next-content-id uint u0)

;; Error codes
(define-constant err-not-owner (err u100))
(define-constant err-already-licensed (err u101))
(define-constant err-license-expired (err u102))
(define-constant err-insufficient-funds (err u103))

;; Functions
(define-public (register-content (title (string-ascii 256)) (license-type (string-ascii 64)) (expiration uint) (price uint))
  (let
    ((content-id (var-get next-content-id)))
    (map-set content-licenses
      { content-id: content-id }
      {
        owner: tx-sender,
        title: title,
        license-type: license-type,
        expiration: expiration,
        price: price
      }
    )
    (var-set next-content-id (+ content-id u1))
    (ok content-id)
  )
)

(define-public (update-content-license (content-id uint) (new-license-type (string-ascii 64)) (new-expiration uint) (new-price uint))
  (let
    ((license (unwrap! (map-get? content-licenses { content-id: content-id }) (err u404))))
    (asserts! (is-eq tx-sender (get owner license)) err-not-owner)
    (ok (map-set content-licenses
      { content-id: content-id }
      (merge license
        {
          license-type: new-license-type,
          expiration: new-expiration,
          price: new-price
        }
      )
    ))
  )
)

(define-public (purchase-license (content-id uint))
  (let
    ((license (unwrap! (map-get? content-licenses { content-id: content-id }) (err u404))))
    (asserts! (is-none (map-get? user-licenses { user: tx-sender, content-id: content-id })) err-already-licensed)
    (try! (stx-transfer? (get price license) tx-sender (get owner license)))
    (ok (map-set user-licenses
      { user: tx-sender, content-id: content-id }
      { expiration: (get expiration license) }
    ))
  )
)

(define-read-only (get-content-license (content-id uint))
  (map-get? content-licenses { content-id: content-id })
)

(define-read-only (check-user-license (user principal) (content-id uint))
  (match (map-get? user-licenses { user: user, content-id: content-id })
    license (ok (> (get expiration license) block-height))
    (err err-license-expired)
  )
)

