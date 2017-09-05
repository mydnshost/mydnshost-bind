# mydnshost-bind

This repo holds the code used to run the bind servers for mydnshost.

This repo is used by both the Master and the Slave servers (with slightly different configs for each.)

The code can be run either with Docker (Master) or directly on a server (Slave Only). In theory both Master/Slave can be either Docker or Direct, but this is not tested.

## Running

TODO...

(Generally: check out the code, `./deploy_local_slave.sh` and/or `./upgrade_local_slave.sh` for slaves, or run the DockerImage with RUNMODE/MASTER/SLAVES/RNDCKEY env vars.)

## Comments, Questions, Bugs, Feature Requests etc.

At some point I'll add more to this README so that this isn't just a code-dump, but for now Bugs and Feature Requests should be raised on the [issue tracker on github](https://github.com/mydnshost/mydnshost-bind/issues), and I'm happy to recieve code pull requests via github.

I can be found idling on various different IRC Networks, but the best way to get in touch would be to message "Dataforce" on Quakenet (or chat in #Dataforce), or drop me a mail (email address is in my github profile)
