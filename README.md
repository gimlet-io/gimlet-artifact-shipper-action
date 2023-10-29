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
  build:
    runs-on: ubuntu-latest
    steps:
    - name: Check out
      uses: actions/checkout@v1
      with:
        fetch-depth: 1
    - name: Build
      run: |
        echo "Here comes your build command"
    - name: Container image
      run: |
        echo "Here you build your container image"
    - name: Deploy with Gimlet
      id: deploy
      uses: gimlet-io/gimlet-artifact-shipper-action@v0.9.0
      env:
        GIMLET_SERVER: ${{ secrets.GIMLET_SERVER }}
        GIMLET_TOKEN: ${{ secrets.GIMLET_TOKEN }}
```

See in action on https://github.com/gimlet-io/github-actions-integration-sample/
