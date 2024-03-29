# ⚠️ TravisCI
As this repository hasn't been actively maintained for a long time, we decided to archive it without migrating from Travis CI to Github Actions. If you plan on unarchiving and making changes to this repository, you have to make sure that old Travis CI/CD jobs found in [.retired-travis.yml](.retired-travis.yml) are converted to Github Actions workflow(s) first.

# Hiera AWS Backend

This backend for [Hiera] allows you to retrieve information from AWS that you
can use in your Puppet code at runtime. For example, you can ask the backend to
get a list of all nodes part of a specific ElastiCache cluster.

This project was inspired by the [hiera-cloudformation] backend.

## Installation

You can install the gem this way:

    $ gem install hiera-aws

## Usage

First, add the backend to the list of backends in `hiera.yaml`:

```yaml
---
:backends:
  - yaml
  - aws
```

Next, add the AWS services supported by this backend to the hierarchy:

```yaml
:hierarchy:
  - aws/elasticache
  - aws/rds
```

The following AWS privileges are required for Hiera to work:

- `AmazonEC2ReadOnlyAccess`
- `AmazonElastiCacheReadOnlyAccess`
- `AmazonRDSReadOnlyAccess`
- `AWSCloudFormationReadOnlyAccess`
- `IAMReadOnlyAccess`

To grant those privileges, you either have to assign the EC2 instances an IAM
role (preferred) or provide credentials for a user with the same privileges via
the backend configuration in `hiera.yml`:

```yaml
:aws:
  :access_key_id: your_aws_access_key_id_here
  :secret_access_key: your_aws_secret_access_key_here
```

In addition to credentials, you can also specify a particular AWS region that
will be used for all AWS API operations:

```yaml
:aws:
  :region: eu-west-1
```

## Hiera Keys

The backend currently supports the following keys that you can pass to the
`hiera()` function to look up objects in AWS.

### redis_cluster_nodes_for_cfn_stack

Returns an array of all Redis cluster nodes for the CloudFormation stack of an
EC2 instance. Only cluster nodes that are in state "available" are returned. The
instance is identified by the Puppet fact `$ec2_instance_id`.

Usage:

```
cluster_nodes = hiera("redis_cluster_nodes_for_cfn_stack")
```

For each Redis cluster node in the array the following hash is returned:

```json
{
    "endpoint" => { "address" => "some.redis.endpoint", "port" => 6379 },
}
```

### redis_cluster_replica_groups_for_cfn_stack

Returns an array of the Redis Replication Groups of all Redis cluster nodes for
the CloudFormation stack of an EC2 Instance. Only Replication Groups that are in
state "available" are returned. The instance is identified by the Puppet fact
`$ec2_instance_id`.

Usage:

```
elasticache_redis_replication_groups = hiera("redis_cluster_replica_groups_for_cfn_stack")
```

For each replica group in the array the following hash is returned:

```json
{
    "replication_group_id" => "some-group-id",
    "primary_endpoint"     => { "address" => "some.replication.group.primary.endpoint", "port" => 1234 },
    "latest_cache_cluster_create_time" => 1400155680
}
```

### memcached_cluster_nodes_for_cfn_stack

Returns an array of all Memcached cluster nodes for the CloudFormation stack of
an EC2 instance. Only cluster nodes that are in state "available" are returned.
The instance is identified by the Puppet fact `$ec2_instance_id`. The returned
array has the format `["host1", "host2"]`.

Usage:

```
cluster_nodes = hiera("memcached_cluster_nodes_for_cfn_stack")
```

### rds_instances tag=value...

Returns an array of all RDS database instances that are in state "available" and
have one or more tags assigned.

For each instance in the array the following hash is returned:

```json
{
    "db_instance_identifier" => "some-instance-identifier",
    "endpoint" => {"address" => "some.rds.endpoint", "port" => 3306},
    "engine" => "mysql"
}
```

Usage:

```
# Get all RDS instances
rds_instances = hiera("rds_instances")

# Get all RDS instances that have a tag named "environment" with the value "dev"
rds_instances = hiera("rds_instances environment=dev")

# Get all RDS instances that have two specific tags
rds_instances = hiera("rds_instances environment=production role=mgmt-db")

# Accessing specific properties of the first RDS instance
$instance_identifier = $rds_instances[0]['db_instance_identifier']
$endpoint_address = $rds_instances[0]['endpoint']['address']
```

### cloudformation stack=<stack-name> output=<output-name>

Returns the value (string) of an output property of the given CloudFormation stack.

Useful for example if you created a AWS access keypair in your CloudFormation
stack and want to access the credentials via hiera.

Usage:

```
# Get output "some_output_key" of CloudFormation stack "some_stack"
value = hiera("cloudformation stack=some_stack output=some_output_key")
```

## License and Authors

* Author:: Mathias Lafeldt (mathias.lafeldt@jimdo.com)
* Author:: Deniz Adrian (deniz.adrian@jimdo.com)
* Author:: Soenke Ruempler (soenke.ruempler@jimdo.com)

Copyright:: 2013-2014, Jimdo GmbH

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

## Contributing

We welcome contributed improvements and bug fixes via the usual workflow:

1. Fork this repository
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new pull request


[Hiera]: http://docs.puppetlabs.com/hiera/1/puppet.html
[hiera-cloudformation]: https://github.com/fanduel/hiera-cloudformation
