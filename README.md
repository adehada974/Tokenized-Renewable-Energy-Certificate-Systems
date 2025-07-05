# Tokenized Renewable Energy Certificate (REC) System

A comprehensive blockchain-based system for managing renewable energy certificates using Clarity smart contracts on the Stacks blockchain.

## Overview

This system consists of five interconnected smart contracts that manage the entire lifecycle of renewable energy certificates:

1. **Generation Verification Contract** - Confirms and tracks clean energy production
2. **Certificate Minting Contract** - Creates tradeable energy credits as tokens
3. **Grid Integration Contract** - Manages renewable energy source connections to power networks
4. **Environmental Impact Contract** - Calculates carbon reduction benefits and environmental metrics
5. **Compliance Reporting Contract** - Handles regulatory requirements and reporting

## Features

### Generation Verification
- Track renewable energy production from various sources (solar, wind, hydro, etc.)
- Verify energy generation data with timestamps and measurements
- Maintain producer registry and source authentication
- Record generation history and performance metrics

### Certificate Minting
- Mint REC tokens based on verified energy generation
- Implement 1:1 ratio (1 MWh = 1 REC token)
- Track token ownership and transfer history
- Manage token metadata and attributes

### Grid Integration
- Register renewable energy sources with grid operators
- Track grid connection status and capacity
- Monitor energy injection into the power network
- Manage grid operator permissions and roles

### Environmental Impact
- Calculate CO2 emissions avoided through renewable energy
- Track environmental benefits and sustainability metrics
- Generate impact reports and carbon credit calculations
- Maintain regional emission factors and conversion rates

### Compliance Reporting
- Generate regulatory compliance reports
- Track certificate retirement and usage
- Maintain audit trails for regulatory bodies
- Handle jurisdiction-specific requirements

## Contract Architecture

Each contract is designed to be self-contained and operates independently:

- \`generation-verification.clar\` - Energy production tracking and verification
- \`certificate-minting.clar\` - REC token creation and management
- \`grid-integration.clar\` - Grid connection and operator management
- \`environmental-impact.clar\` - Carbon footprint and impact calculations
- \`compliance-reporting.clar\` - Regulatory compliance and reporting

## Token Economics

- **REC Tokens**: Fungible tokens representing 1 MWh of renewable energy
- **Generation Credits**: Non-fungible tokens representing specific generation events
- **Impact Certificates**: Tokens representing environmental benefits achieved

## Getting Started

### Prerequisites
- Stacks blockchain development environment
- Clarity smart contract deployment tools
- Node.js for running tests

### Installation
1. Clone the repository
2. Install dependencies: \`npm install\`
3. Run tests: \`npm test\`
4. Deploy contracts to testnet/mainnet

### Testing
Tests are written using Vitest and cover:
- Contract deployment and initialization
- Energy generation verification
- Certificate minting and transfers
- Grid integration workflows
- Environmental impact calculations
- Compliance reporting functions

## Usage Examples

### Register Energy Producer
\`\`\`clarity
(contract-call? .generation-verification register-producer
"Solar Farm Alpha"
"solar"
u1000000) ;; 1MW capacity
\`\`\`

### Record Energy Generation
\`\`\`clarity
(contract-call? .generation-verification record-generation
u1 ;; producer-id
u500000 ;; 500 kWh generated
u1640995200) ;; timestamp
\`\`\`

### Mint REC Certificate
\`\`\`clarity
(contract-call? .certificate-minting mint-certificate
'SP1HTBVD3JG9C05J7HBJTHGR0GGW7KX17ECNP0AH0 ;; recipient
u500 ;; 500 kWh = 0.5 MWh
u1) ;; generation-id
\`\`\`

## Security Considerations

- All contracts implement proper access controls
- Generation data requires verification before certificate minting
- Grid integration requires operator approval
- Environmental calculations use verified emission factors
- Compliance reports maintain immutable audit trails

## Regulatory Compliance

The system is designed to meet various regulatory requirements:
- REC tracking and retirement standards
- Environmental attribute verification
- Grid operator reporting requirements
- Carbon credit calculation standards
- Audit trail maintenance for regulatory bodies

## Contributing

1. Fork the repository
2. Create a feature branch
3. Write tests for new functionality
4. Ensure all tests pass
5. Submit a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.
