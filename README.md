Distill
=======
Puppet template engine using hierarchical substitution.

Substitution is normally usefull when you can map locations or an organistaion using a hierarchy.

Examples
--------
Example of an Substition sequence.

<pre>
Default -> Region -> Country -> Datacenter -> Business Unit -> Owner -> Host Group -> Host 
</pre>

In the top level you keep default's and then substitute them with more and more granular values.

This is an example template that says for the Region EMEA call the Class *resolv* and pass the parameter *dns_servers* with the above values.

*region/emea.json*
<pre>
{
    "resolv::dns_servers": [
        "192.168.1.1",
        "192.168.1.2"
    ]
}
</pre>

This is an example template that says for the Country Switzerland call the Class *resolv* and pass the parameter *dns_servers* with the above values.

*country/ch.json*
<pre>
{
    "resolv::dns_servers": [
	"10.0.1.1",
        "10.0.2.1"
    ]
}
</pre>

This is an exmaple template that says for Datacenter in Zurich Unset the DNS Server 10.0.2.1 and then add the DNS server 10.0.3.1 instead.

*datacenter/zurich.json*
<pre>
{
    "u:resolv::dns_servers": [
        "10.0.2.1"
    ],
    "m:resolv::dns_servers": [
        "10.0.3.1"
    ]
}
</pre>

This is an example template that says for the Host Group *mysql_server* configure mysql client and server, additionally setup 2 users.

*host_group/mysql_server.json*
<pre>
    "mysql::client::version": "5.0.1",
    "mysql::server::version": "5.0.1",
    "mysql::server::user::users": {
        "user1": {
            "host": "%",
            "password": "*6691484EA6B50DDDE1926A220DA01FA9E575C18A"
        },
        "user2": {
            "host": "%",
            "password": "*6691484EA6B50DDDE1926A220DA01FA9E575C18A"
        }
    }
}
</pre>

This is an example template that says for the Host *testbox* setup an additional mysql user.

*host/testbox.foo.bar.json*
<pre>
{
    "m:mysql::server::user::users": {
        "user3": {
            "host": "%",
            "password": "*6691484EA6B50DDDE1926A220DA01FA9E575C18A"
        }
    }
}
</pre>

The output from the following will be an ENC in YAML format.

*Output YAML ENC*
<pre>
---
classes:
  resolv:
    dns_servers:
      - 10.0.1.1
      - 10.0.3.1
  mysql::client:
    version: 5.0.1
  mysql::server:
    version: 5.0.1
  mysql::server::user
    users:
      user1:
        host: %
        password: *6691484EA6B50DDDE1926A220DA01FA9E575C18A
      user2:
         host: %
         password: *6691484EA6B50DDDE1926A220DA01FA9E575C18A
      user3:
         host: %
         password: *6691484EA6B50DDDE1926A220DA01FA9E575C18A
parameters:
  default: default
  region: emea
  country: ch
  datacenter: zurich
  business_unit: operations
  owner: user1
  host_group: mysql_server
  host: testbox.foo.bar
  distill_environment: production
  distill_server: distill.foo.bar
  host: testbox.foo.bar
  puppet_environment: production
</pre>

In this fashion you can create a very fine grained configuration outside of Puppet. The whole idea is too keep Configuration separate from Code. Otherwise you have to re-test your Code everytime you make a change.

Features
--------

Distill also supports some advanced operations:

- Unset field, array item, hash key
- Merge arrays/hashes
- Immutable ie. prevent a field from being substituted at a lower hieararchy
- Reference other fields

Templates in Distill are created using JSON files. All values used for substitution are fetched from either the Distill input method or as a Puppet Fact.

Distill can run on a different server then the Puppet server thanks to it's REST Web API.

Distill Schema
==============
Distill Schema is an extension to Distill that allows for the creation of JSON Schemas that can verify a configuration before it's applied to production.

Installation
============
Download the Admin Guide PDF inside the pdfs directory.

License
=======
See LICENSE file in trunk.
