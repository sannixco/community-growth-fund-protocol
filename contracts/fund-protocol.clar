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
