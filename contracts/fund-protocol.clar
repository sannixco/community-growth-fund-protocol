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

;; -----------------------------------------
;; Data Storage & State Management
;; -----------------------------------------

;; Core project information
(define-map Projects
  { id: uint }
  {
    creator: principal,
    funding-goal: uint,
    current-funding: uint,
    end-block: uint,
    status: (string-ascii 10)
  }
)

;; Backer contribution records
(define-map FundingContributions
  { id: uint, backer: principal }
  { contribution-amount: uint }
)

;; Counter for assigning unique project IDs
(define-data-var project-id-counter uint u0)

;; Project description metadata
(define-map ProjectDetails
  { id: uint }
  {
    name: (string-utf8 100),
    summary: (string-utf8 500),
    project-url: (string-utf8 100),
    project-type: (string-ascii 20)
  }
)

;; Project development phases
(define-map ProjectPhases
  { id: uint, phase-id: uint }
  {
    phase-description: (string-utf8 200),
    phase-funding: uint,
    phase-complete: bool
  }
)

;; Counter for project phases
(define-map PhaseCounter
  { id: uint }
  { phase-count: uint }
)

;; Allowlist for restricted projects
(define-map ParticipantAllowlist
  { id: uint, participant: principal }
  { is-allowed: bool }
)

;; Rate limiting for contributions
(define-map ContributionRateLimit
  { backer: principal }
  {
    last-contribution-block: uint,
    contribution-count: uint
  }
)

;; Pending ownership transfer requests
(define-map OwnershipTransfers
  { id: uint }
  { proposed-owner: principal }
)

;; Fund withdrawal requests
(define-map WithdrawalRequests
  { id: uint }
  {
    request-block: uint,
    withdrawal-amount: uint
  }
)

;; Creator reputation metrics
(define-map CreatorReputation
  { creator: principal }
  {
    completed-projects: uint,
    unsuccessful-projects: uint,
    funds-raised: uint
  }
)

;; Withdrawal controls for fund management
(define-map FundWithdrawalControls
  { id: uint }
  {
    daily-max: uint,
    last-withdrawal-block: uint,
    withdrawn-total: uint
  }
)

;; Security configuration for high-value operations
(define-map SecuritySettings
  { id: uint }
  {
    secondary-approver: (optional principal),
    security-threshold: uint,
    required-approvals: uint
  }
)

;; Multi-signature operation requests
(define-map PendingApprovals
  { id: uint, operation-code: (string-ascii 20) }
  {
    requester: principal,
    approvers: (list 10 principal),
    expiration-block: uint,
    operation-details: (string-utf8 200)
  }
)

;; Emergency fund recovery requests
(define-map EmergencyFundRecovery
  { id: uint }
  {
    request-block: uint,
    admin-approved: bool,
    creator-approved: bool,
    recovery-address: principal
  }
)

;; Backer diversity tracking
(define-map UniqueBackerCount
  { id: uint }
  { distinct-backers: uint }
)

;; -----------------------------------------
;; Core Helper Functions
;; -----------------------------------------

;; Verifies that a project exists
(define-private (does-project-exist (id uint))
  (<= id (var-get project-id-counter))
)

;; Checks if a project is in a valid state for funding
(define-private (can-accept-funding (status (string-ascii 10)))
  (is-eq status "active")
)

;; -----------------------------------------
;; Project Creation & Management
;; -----------------------------------------

;; Creates a new community funding project
(define-public (create-funding-project (funding-goal uint))
  (begin
    (asserts! (> funding-goal u0) (err ERROR_FUNDING_PARAMETER))
    (let
      (
        (new-id (+ (var-get project-id-counter) u1))
        (project-end-block (+ block-height FUNDING_DURATION))
      )
      (map-set Projects
        { id: new-id }
        {
          creator: tx-sender,
          funding-goal: funding-goal,
          current-funding: u0,
          end-block: project-end-block,
          status: "active"
        }
      )
      (var-set project-id-counter new-id)
      (print {event: "project_created", id: new-id, creator: tx-sender, goal: funding-goal})
      (ok new-id)
    )
  )
)

;; Manages participant allowlist for restricted projects
(define-public (update-participant-allowlist (id uint) (participant principal) (status bool))
  (begin
    (asserts! (does-project-exist id) (err ERROR_NONEXISTENT_PROJECT))
    (let
      (
        (project-data (unwrap! (map-get? Projects { id: id }) (err ERROR_NONEXISTENT_PROJECT)))
        (project-creator (get creator project-data))
      )
      ;; Only project creator can manage allowlist
      (asserts! (is-eq tx-sender project-creator) (err ERROR_PERMISSION_DENIED))

      (print {event: "allowlist_updated", id: id, participant: participant, status: status})
      (ok true)
    )
  ))

;; Adds development phases to a project
(define-public (create-project-phase 
    (id uint) 
    (phase-description (string-utf8 200))
    (phase-funding uint))
  (begin
    (asserts! (does-project-exist id) (err ERROR_NONEXISTENT_PROJECT))
    (asserts! (> phase-funding u0) (err ERROR_FUNDING_PARAMETER))
    (let
      (
        (project-data (unwrap! (map-get? Projects { id: id }) (err ERROR_NONEXISTENT_PROJECT)))
        (project-creator (get creator project-data))
        (project-status (get status project-data))
        (phase-data (default-to { phase-count: u0 } (map-get? PhaseCounter { id: id })))
        (next-phase-id (+ (get phase-count phase-data) u1))
      )
      ;; Only project creator can add phases
      (asserts! (is-eq tx-sender project-creator) (err ERROR_PERMISSION_DENIED))
      ;; Can only add phases to active projects
      (asserts! (is-eq project-status "active") (err ERROR_PROJECT_ALREADY_CLOSED))
      (map-set PhaseCounter
        { id: id }
        { phase-count: next-phase-id }
      )
      (print {event: "phase_created", id: id, phase-id: next-phase-id})
      (ok true)
    )
  )
)


;; -----------------------------------------
;; Funding & Financial Operations
;; -----------------------------------------

;; Standard contribution function
(define-public (contribute-to-project (id uint) (contribution-amount uint))
  (begin
    (asserts! (> contribution-amount u0) (err ERROR_FUNDING_PARAMETER))
    (asserts! (does-project-exist id) (err ERROR_NONEXISTENT_PROJECT))
    (let
      (
        (project-data (unwrap! (map-get? Projects { id: id }) (err ERROR_NONEXISTENT_PROJECT)))
        (project-status (get status project-data))
        (total-funding (get current-funding project-data))
        (new-funding-total (+ total-funding contribution-amount))
      )
      (asserts! (can-accept-funding project-status) (err ERROR_PROJECT_ALREADY_CLOSED))
      (asserts! (<= block-height (get end-block project-data)) (err ERROR_PROJECT_ALREADY_CLOSED))
      (match (stx-transfer? contribution-amount tx-sender (as-contract tx-sender))
        success
          (begin
            (map-set Projects
              { id: id }
              (merge project-data { current-funding: new-funding-total })
            )
            (map-set FundingContributions
              { id: id, backer: tx-sender }
              { contribution-amount: contribution-amount }
            )
            (print {event: "contribution_received", id: id, backer: tx-sender, amount: contribution-amount})
            (ok true)
          )
        failure (err ERROR_TRANSFER_FAILED)
      )
    )
  )
)

;; Contribution function with rate limiting
(define-public (contribute-with-rate-limit (id uint) (contribution-amount uint))
  (begin
    (asserts! (> contribution-amount u0) (err ERROR_FUNDING_PARAMETER))
    (asserts! (does-project-exist id) (err ERROR_NONEXISTENT_PROJECT))
    (let
      (
        (rate-data (default-to 
                          { last-contribution-block: u0, contribution-count: u0 } 
                          (map-get? ContributionRateLimit { backer: tx-sender })))
        (previous-block (get last-contribution-block rate-data))
        (current-transactions (get contribution-count rate-data))
        (window-expired (> (- block-height previous-block) u72))
      )
      ;; Check rate limits
      (asserts! (or window-expired (< current-transactions u5)) (err ERROR_RATE_LIMIT_EXCEEDED))

      ;; Update rate limit tracking
      (map-set ContributionRateLimit
        { backer: tx-sender }
        {
          last-contribution-block: block-height,
          contribution-count: (if window-expired u1 (+ current-transactions u1))
        }
      )

      ;; Proceed with regular contribution function
      (contribute-to-project id contribution-amount)
    )
  )
)

;; Enhanced contribution function with additional security
(define-public (secured-contribution (id uint) (contribution-amount uint))
  (begin
    (asserts! (> contribution-amount u0) (err ERROR_FUNDING_PARAMETER))
    (asserts! (<= contribution-amount u50000000000) (err ERROR_CONTRIBUTION_EXCEEDS_LIMIT))
    (asserts! (does-project-exist id) (err ERROR_NONEXISTENT_PROJECT))
    (let
      (
        (project-data (unwrap! (map-get? Projects { id: id }) (err ERROR_NONEXISTENT_PROJECT)))
        (project-status (get status project-data))
        (total-funding (get current-funding project-data))
        (new-funding-total (+ total-funding contribution-amount))
        (backer-data (default-to { contribution-amount: u0 } 
                        (map-get? FundingContributions { id: id, backer: tx-sender })))
        (previous-contribution (get contribution-amount backer-data))
        (backer-total-contribution (+ previous-contribution contribution-amount))
      )
      ;; Check contribution limits for individual backer
      (asserts! (<= backer-total-contribution u50000000000) (err ERROR_CONTRIBUTION_EXCEEDS_LIMIT))
      (asserts! (can-accept-funding project-status) (err ERROR_PROJECT_ALREADY_CLOSED))
      (asserts! (<= block-height (get end-block project-data)) (err ERROR_PROJECT_ALREADY_CLOSED))

      (match (stx-transfer? contribution-amount tx-sender (as-contract tx-sender))
        success
          (begin
            (map-set Projects
              { id: id }
              (merge project-data { current-funding: new-funding-total })
            )
            (map-set FundingContributions
              { id: id, backer: tx-sender }
              { contribution-amount: backer-total-contribution }
            )
            (print {event: "secured_contribution_received", id: id, backer: tx-sender, amount: contribution-amount})
            (ok true)
          )
        failure (err ERROR_TRANSFER_FAILED)
      )
    )
  )
)

;; Collect funds for a successfully funded project
(define-public (withdraw-project-funds (id uint))
  (begin
    (asserts! (does-project-exist id) (err ERROR_NONEXISTENT_PROJECT))
    (let
      (
        (project-data (unwrap! (map-get? Projects { id: id }) (err ERROR_NONEXISTENT_PROJECT)))
        (project-creator (get creator project-data))
        (funding-goal (get funding-goal project-data))
        (available-funds (get current-funding project-data))
        (project-status (get status project-data))
      )
      (asserts! (is-eq tx-sender project-creator) (err ERROR_PERMISSION_DENIED))
      (asserts! (is-eq project-status "active") (err ERROR_PROJECT_ALREADY_CLOSED))
      (asserts! (>= available-funds funding-goal) (err ERROR_INSUFFICIENT_FUNDS))
      (match (as-contract (stx-transfer? available-funds tx-sender project-creator))
        success
          (begin
            (map-set Projects
              { id: id }
              (merge project-data { status: "completed" })
            )
            (print {event: "funds_withdrawn", id: id, amount: available-funds})
            (ok true)
          )
        failure (err ERROR_TRANSFER_FAILED)
      )
    )
  )
)

;; Initiates a time-locked withdrawal process for large amounts
(define-public (request-large-withdrawal (id uint))
  (begin
    (asserts! (does-project-exist id) (err ERROR_NONEXISTENT_PROJECT))
    (let
      (
        (project-data (unwrap! (map-get? Projects { id: id }) (err ERROR_NONEXISTENT_PROJECT)))
        (project-creator (get creator project-data))
        (funding-goal (get funding-goal project-data))
        (available-funds (get current-funding project-data))
        (project-status (get status project-data))
      )
      ;; Only project creator can request withdrawal
      (asserts! (is-eq tx-sender project-creator) (err ERROR_PERMISSION_DENIED))
      ;; Can only withdraw from active projects
      (asserts! (is-eq project-status "active") (err ERROR_PROJECT_ALREADY_CLOSED))
      ;; Must have reached funding goal
      (asserts! (>= available-funds funding-goal) (err ERROR_INSUFFICIENT_FUNDS))

      ;; If large withdrawal, apply timelock
      (if (>= available-funds u1000000000)
        (begin
          (map-set WithdrawalRequests
            { id: id }
            {
              request-block: block-height,
              withdrawal-amount: available-funds
            }
          )
          (print {event: "withdrawal_requested", id: id, amount: available-funds})
          (ok true)
        )
        ;; For smaller amounts, proceed with immediate withdrawal
        (withdraw-project-funds id)
      )
    )
  )
)
