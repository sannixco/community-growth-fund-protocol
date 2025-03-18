;; Community Growth Fund Protocol (CGFP)
;; A decentralized funding platform built on Stacks blockchain
;; This smart contract enables community-driven project funding with transparent management

;; -----------------------------------------
;; Core Protocol Configuration
;; -----------------------------------------
(define-constant CONTRACT_ADMINISTRATOR tx-sender)
(define-constant FUNDING_DURATION u2016) ;; Project funding window (2 weeks at 10-min block intervals)

;; -----------------------------------------
;; Error Code Definitions
;; -----------------------------------------
(define-constant ERROR_PERMISSION_DENIED (err u200))
(define-constant ERROR_NONEXISTENT_PROJECT (err u201))
(define-constant ERROR_FUNDING_PARAMETER (err u202))
(define-constant ERROR_PROJECT_ALREADY_CLOSED (err u203))
(define-constant ERROR_INSUFFICIENT_FUNDS (err u204))
(define-constant ERROR_TRANSFER_FAILED (err u205))
(define-constant ERROR_CONTRIBUTION_EXCEEDS_LIMIT (err u206))
(define-constant ERROR_NOT_ON_ALLOWLIST (err u207))
(define-constant ERROR_REFUNDS_UNAVAILABLE (err u212))
(define-constant ERROR_NO_REFUNDABLE_AMOUNT (err u213))
(define-constant ERROR_OWNERSHIP_TRANSFER_FAILED (err u214))
(define-constant ERROR_RATE_LIMIT_EXCEEDED (err u220))
(define-constant ERROR_SECURITY_VALIDATION_NEEDED (err u230))
(define-constant ERROR_DUPLICATE_CONFIRMATION (err u231))
(define-constant ERROR_EXPIRED_CONFIRMATION (err u232))
(define-constant ERROR_NO_EMERGENCY_REQUEST (err u240))
(define-constant ERROR_WAITING_PERIOD_ACTIVE (err u241))
(define-constant ERROR_BACKER_DIVERSITY_INSUFFICIENT (err u250))

