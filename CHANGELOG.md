## v0.6.1 (Mar 2 2014)

* Fix gem dependencies to depend on aws-sdk version 1.x. This fixes the
  installation of hiera-aws on a clean system. Thanks to @gdhbashton for
  reporting the bug.

## v0.6.0 (Aug 4 2014)

* Added `cloudformation` in order to allow querying CloudFormation outputs.

## v0.5.0 (May 15 2014)

* Change `redis_cluster_nodes_for_cfn_stack`, `memcached_cluster_nodes_for_cfn_stack`,
  and `redis_cluster_replica_groups_for_cfn_stack` to only return resources that
  are in state "available".
* Change `redis_cluster_replica_groups_for_cfn_stack` response to include
  `latest_cache_cluster_create_time`, which is the creation time unix timestamp
  of the most current cache cluster in each replication group.

## v0.4.1 (May 12 2014)

* Disable real HTTP connections in RSpec tests by using
  [WebMock](https://github.com/bblimke/webmock).

## v0.4.0 (May 8 2014)

* Change `redis_cluster_nodes_for_cfn_stack` to return endpoint address and port
  as a hash, which is the same format used elsewhere.
* Update to latest RuboCop version.

## v0.3.0

## v0.2.0

## v0.1.0

## v0.0.8

## v0.0.7

## v0.0.6

## v0.0.5

## v0.0.4

## v0.0.3

## v0.0.2

## v0.0.1
