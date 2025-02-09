;; Streaming Token Contract

;; Define token
(define-fungible-token streaming-token)

;; Define data structures
(define-map subscriptions
  { user: principal }
  { expiration: uint }
)

;; Constants
(define-constant subscription-price u100000000) ;; 100 tokens
(define-constant subscription-duration u43200) ;; ~30 days (assuming 144 blocks per day)

;; Error codes
(define-constant err-insufficient-balance (err u200))
(define-constant err-active-subscription (err u201))

;; Functions
(define-public (mint (amount uint))
  (ft-mint? streaming-token amount tx-sender)
)

(define-public (transfer (amount uint) (recipient principal))
  (ft-transfer? streaming-token amount tx-sender recipient)
)

(define-public (subscribe)
  (let
    ((current-balance (ft-get-balance streaming-token tx-sender)))
    (asserts! (>= current-balance subscription-price) err-insufficient-balance)
    (asserts! (is-none (map-get? subscriptions { user: tx-sender })) err-active-subscription)
    (try! (ft-burn? streaming-token subscription-price tx-sender))
    (ok (map-set subscriptions
      { user: tx-sender }
      { expiration: (+ block-height subscription-duration) }
    ))
  )
)

(define-read-only (check-subscription (user principal))
  (match (map-get? subscriptions { user: user })
    subscription (> (get expiration subscription) block-height)
    false
  )
)

(define-read-only (get-balance (user principal))
  (ok (ft-get-balance streaming-token user))
)
