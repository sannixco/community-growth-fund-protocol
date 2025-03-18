# Community Growth Fund Protocol (CGFP)

The Community Growth Fund Protocol (CGFP) is a decentralized funding platform built on the Stacks blockchain. It allows community members to fund projects with transparency, utilizing smart contracts for project creation, fund management, and contributor involvement.

## Table of Contents
- [Introduction](#introduction)
- [Features](#features)
- [Core Components](#core-components)
- [Smart Contract Logic](#smart-contract-logic)
- [How to Use](#how-to-use)
- [Deployment](#deployment)
- [Security Features](#security-features)
- [Contributing](#contributing)
- [License](#license)

## Introduction

CGFP leverages the power of blockchain technology to create a decentralized platform where users can fund projects, monitor progress, and ensure the transparent allocation of funds. This platform enables creators to manage project funding goals, timelines, and phases while ensuring security, privacy, and permission controls for contributors.

## Features

- **Project Creation**: Allows users to create funding projects with a specified goal and duration.
- **Community Contributions**: Users can contribute to projects during the active funding window.
- **Phase Management**: Projects can be divided into phases, each with its own funding goal.
- **Allowlist Management**: Projects can have restricted participation using an allowlist for specific contributors.
- **Security & Rate Limiting**: Implements security validation, multi-signature approvals, and rate limiting for contributions to avoid malicious activity.
- **Emergency Fund Recovery**: In case of project failure or mismanagement, the protocol includes an emergency fund recovery mechanism.
- **Reputation Metrics**: Tracks the success and failure of project creators, incentivizing high-quality projects.

## Core Components

- **Projects**: Stores project details such as the creator, funding goal, current funding, and project status.
- **FundingContributions**: Tracks backer contributions for each project.
- **Phase Management**: Manages the development phases for each project, including funding milestones and completion status.
- **Allowlist**: Manages a list of allowed participants for specific projects.
- **SecuritySettings**: Defines thresholds and secondary approvers for sensitive operations.
- **Reputation**: Tracks the reputation of creators based on completed projects and funds raised.
- **Emergency Fund Recovery**: Stores and manages emergency fund recovery requests.

## Smart Contract Logic

The core of the protocol consists of several smart contract functions written in Clarity, the language for the Stacks blockchain. Key functions include:

- **create-funding-project**: Allows users to create a funding project with a specified goal and timeline.
- **update-participant-allowlist**: Manages the allowlist for each project, ensuring only authorized participants can contribute.
- **create-project-phase**: Allows creators to divide their project into phases, each with its own funding target.
- **contribute-to-project**: Lets users contribute funds to a project while ensuring conditions like project status and funding goals are met.

The contract also supports error handling for various scenarios, including permission issues, insufficient funds, and invalid project states.

## How to Use

1. **Deploy the Smart Contract**: Deploy the CGFP contract to the Stacks blockchain.
2. **Create a Funding Project**: Call `create-funding-project` with a funding goal.
3. **Add Phases**: Create development phases for your project using `create-project-phase`.
4. **Accept Contributions**: Allow users to contribute funds to the project via `contribute-to-project`.
5. **Manage Contributors**: Use the allowlist to restrict contributors if needed.
6. **Withdraw Funds**: Withdraw funds according to the defined withdrawal policies and controls.

## Deployment

To deploy the smart contract on the Stacks blockchain:

1. Set up a Stacks environment with necessary tools.
2. Compile and deploy the contract to the blockchain using your preferred Stacks wallet and interface.

## Security Features

The protocol includes several important security mechanisms:

- **Multi-Signature Approvals**: Sensitive operations require approvals from multiple parties.
- **Rate Limiting**: Contributions are rate-limited to prevent abuse and ensure fairness.
- **Emergency Fund Recovery**: A mechanism for recovering funds in case of mismanagement.
- **Project Status**: Projects are marked as active or closed, preventing further contributions after the funding window expires.

## Contributing

We welcome contributions! If you'd like to contribute to the development of CGFP, please follow these steps:

1. Fork the repository.
2. Create a new branch for your feature or bug fix.
3. Commit your changes and push them to your fork.
4. Open a pull request to the `main` branch.

Before submitting, ensure your code adheres to our coding standards and includes necessary tests.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## Contact

For any inquiries or support, feel free to reach out through GitHub issues 

