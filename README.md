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
  --pre-destructive-changes destructive/destructiveChanges.xml \
  --manifest destructive/package.xml
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
- `sf package version create --path force-app --installation-key cvt1 --code-coverage`
- `sf package version promote --package 04tgK0000005CbdQAE`

## Installation

Via CLI

```
sf package install --package 04tgK0000005CbdQAE --installation-key cvt1
```

## Via browser

Go to https://login.salesforce.com/packaging/installPackage.apexp?p0=04tgK0000005CbdQAE \
Use password `cvt1`
Follow the post-installation steps described here:
https://www.cv-transformer.com/en/docs/integrations/salesforce
