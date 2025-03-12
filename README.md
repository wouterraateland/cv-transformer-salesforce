## Installation

- Install `sf` CLI
- Install `openjdk@21`

## Deploying a new dev version

- `sf project deploy start`

## Testing

- Run tests: `sf apex run test --result-format human --code-coverage --wait 10`

## Updating the package

- `sf package version create --path force-app --installation-key cvt1 --code-coverage`
- `sf package install --package 04tgK00000009T7QAI --installation-key cvt1`
- `sf package version promote --package 04tgK00000009T7QAI`
