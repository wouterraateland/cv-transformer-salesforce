## Installation

- Install `sf` CLI
- Install `openjdk@21`

## Deploying dev version

```
sf project deploy start
```

## Removing dev version

```
sf project deploy start \
  --pre-destructive-changes manifests/components.xml \
  --manifest manifests/empty.xml
```

## Running tests

```
sf apex run test --result-format human --code-coverage --wait 10
```

## View API limits

```
sf force limits api display
```

## Updating the package

- Increment version in `sfdx-project.json`
- `sf package version create --path force-app --installation-key-bypass --code-coverage`
- `sf package version promote --package 04tgK000000E03NQAS`

## Installation

Via CLI

```
sf package install --package 04tgK000000E03NQAS --installation-key-bypass
```

## Via browser

Go to https://login.salesforce.com/packaging/installPackage.apexp?p0=04tgK000000E03NQAS
Follow the post-installation steps described here:
https://www.cv-transformer.com/en/docs/integrations/salesforce-beta
