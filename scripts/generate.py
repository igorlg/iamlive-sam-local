#!/usr/bin/env python

import json
import yaml
import argparse

import deep_merge


iamlive_container = 'iamlive'
iamlive_port      = 10080
docker_network    = 'my-net'

out = {}
funcs = []
env_vars = {
        "HTTP_PROXY": f"http://{iamlive_container}.{docker_network}:{iamlive_port}",
        "HTTPS_PROXY": f"http://{iamlive_container}.{docker_network}:{iamlive_port}",
        "AWS_CA_BUNDLE": "/var/task/ca.pem"
        }

def parse_args(argv=None):
    parser = argparse.ArgumentParser()
    parser.add_argument('-a', '--action', choices=['env-vars', 'template'], required=True)
    parser.add_argument('-t', '--template_file', type=str, default='template.yaml')
    parser.add_argument('-o', '--output', type=str, default='')
    return parser.parse_args(argv)

def get_template(args):
    with open(args.template_file, 'r') as f:
        return yaml.load(f, Loader=yaml.FullLoader)

def output(args, value):
    if args.output:
        with open(args.output, 'w') as f:
            f.write(value)
    else:
        print(value)

def gen_env_vars(args):
    tmpl = get_template(args)
    out = {k: env_vars for k, v in tmpl['Resources'].items() if v['Type'].endswith('Function')}
    output(args, json.dumps(out, indent=4))

def gen_template(args):
    tmpl = get_template(args)
    vars_dict = {'Globals': {'Function': {'Environment': {'Variables': {k: '' for k, v in env_vars.items()}}}}}
    deep_merge.merge(tmpl, vars_dict)
    output(args, yaml.dump(tmpl))

def main(args):
    if args.action == 'env-vars':
        gen_env_vars(args)
    elif args.action == 'template':
        gen_template(args)


if __name__ == '__main__':
    main(parse_args())

