Demo of how to run [iamlive](https://github.com/iann0036/iamlive) with SAM Local, useful for generating IAM Policies as part of CI builds.

Questions via Issues and PRs are welcome!

> by Igor Gentil <igorlg@amazon.com> and Geoff Singer <singergs@amazon.com>

# Start Here

Run `make init` to install script requirements, create a user-defined Docker Network and build the iamlive Docker image:

```bash
$ make init

pip install -r scripts/requirements.txt
docker network ls | grep my-net >/dev/null 2>&1 || docker network create my-net
/Applications/Xcode.app/Contents/Developer/usr/bin/make build-iamlive
curl -fsSL https://github.com/iann0036/iamlive/releases/download/v0.42.0/iamlive-v0.42.0-linux-amd64.tar.gz -o iamlive/iamlive-v0.42.0-linux-amd64.tar.gz
tar -C iamlive/ -zxf iamlive/iamlive-v0.42.0-linux-amd64.tar.gz
rm -f iamlive/iamlive-v0.42.0-linux-amd64.tar.gz
docker build -t iamlive-run iamlive/
[+] Building 0.2s (8/8) FINISHED
```

# End-to-end Execution

After building the iamlive image and creating the Docket network (see #Start Here), run `make all` to:

1. Start the iamlive Docker container
2. Run your lambda function using `sam local invoke`
3. Generate the IAM Policy output in `iamlive.log`

```bash
$ make all

[...]

{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [...],
      "Resource": [...]
    }
  ]
}
```

# Run only the Lambda function

You can also keep the iamlive proxy running and run the Lambda function multiple times, like so:

```bash
$ make iamlive-proxy

## running lambda
$ make sam iamlive-output
# [lambda runs]
#
# [generate iamlive.log and display output]]

## running lambda again
$ make sam iamlive-output
[...]
```

To finish, run `make clean` to remove the temporary files *and the iamlive.log output*!

```bash
$ make clean

docker kill iamlive 2>/dev/null || true
find . -type f -name ca.pem -delete
rm -f iamlive.log env-vars.json template-gen.yaml
```

# scripts/generate.py

One of the pre-requisites for this solution to work is that three Environment variables need to be set in the Lambda container, so it can proxy requests to iamlive. These variables are:

- HTTP_PROXY
- HTTPS_PROXY
- AWS_CA_BUNDLE

> Details on why they are required can be found [here](https://github.com/iann0036/iamlive#proxy-mode)

In order to make this work, two conditions need to be satisfied:

1. The variables are set in a JSON file, which is passed to `sam local invoke`, and
2. the variables need to exist in the SAM template.

To avoid requiring the users to set these themselves in their functions, this script creates a temporary copy of `template.yaml`, adds the variables to the `Globals` section and generates a (temporary) `env-vars.json` file. Running `make clean` - which is part of `make all` - will remove these files.
