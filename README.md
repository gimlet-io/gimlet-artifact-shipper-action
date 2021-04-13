# Gimlet Artifact Shipper Github Action

## Testing locally

```
docker build -t myaction .
docker run -v $(pwd):/action -it -e GITHUB_REF=refs/tags/alma myaction docker-image=mycompany/myimage:mytag "true"
```
