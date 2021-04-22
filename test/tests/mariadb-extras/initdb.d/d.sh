#!/bin/false source me, I have no execute perms

# Being sourced, the internal functions of the entrypoint are an API
docker_process_sql <<<'update t1 set i=i*3'
