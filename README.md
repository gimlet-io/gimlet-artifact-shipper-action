# Gimlet Artifact Shipper Github Action

## Testing locally

```
docker build -t myaction .
docker run -v $(pwd):/action -it -e GITHUB_REF=refs/tags/alma myaction docker-image=mycompany/myimage:mytag "true"
```

## Usage

```yaml
name: Build
on:
  push:
    branches:
      - 'main'

jobs:
  shipping-artifact:
    runs-on: ubuntu-latest
    name: "Shipping artifact"
    needs:
    - docker-build
    steps:
    - name: Check out
      uses: actions/checkout@v1
      with:
        fetch-depth: 1
    - name: Shipping release artifact to Gimlet
      id: shipping
      uses: gimlet-io/gimlet-artifact-shipper-action@v0.8.3
      env:
        GIMLET_SERVER: ${{ secrets.GIMLET_SERVER }}
        GIMLET_TOKEN: ${{ secrets.GIMLET_TOKEN }}
    - name: Artifact ID
      run: echo "Artifact ID is ${{ steps.shipping.outputs.artifact-id }}"
```

See in action on https://github.com/gimlet-io/github-actions-integration-sample/
