## Installation

- Install `sf` CLI
- Install `openjdk@21`

## Deploying a new dev version

- `sf project deploy start`

## Testing

- Run tests: `sf apex run test --result-format human --code-coverage --wait 10`

## Updating the package

- `sf package version create --path force-app --installation-key cvt1 --code-coverage`
- `sf package version promote --package 04tgK00000009cnQAA`
- `sf package install --package 04tgK00000009cnQAA --installation-key cvt1`

## Installation on a new org

Go to https://login.salesforce.com/packaging/installPackage.apexp?p0=04tgK00000009cnQAA \
Use password `cvt1`
