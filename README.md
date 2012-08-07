Distill
=======
Puppet template engine using hierarchical substitution.

Description
-----------
A common issue in Puppet is that you end up with a lot of logic just to determine the configuration based on certain criteria. Also changing this becomes a problem since you need to re-test your code for every change.

In most programming languages it's common practice to keep Configuration separate from the actual code, this is why Distill came into existence too fill this gap. It consists of 2 part's the first is to template a configuration for hosts based on certain criteria's and the second part is to validate the actual result of these templates.

Additional advantages of this approach is that it makes it very easy to detect changes for host configuration:
- When it was changed
- What was changed
- Who changed it

This does however assume you store your Templates in version control, which is highly encouraged.

Since Distill also comes with a Web REST API it makes the host configuration available too your own glue scripts in a very simple manner.

Examples
--------
Example of an Substitution sequence.

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

This is an example template that says for Datacenter in Zurich Unset the DNS Server 10.0.2.1 and then merge the DNS server 10.0.3.1 instead.

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

In this fashion you can create a very fine grained configuration outside of Puppet. The whole idea is too keep Configuration separate from Code. Otherwise you have to re-test your Code every-time you make a change.

Features
--------
- Separate environment's with individual templates and substitution sequences
- Web REST API
- Standalone server, doesn't need to run on the Puppet server

*Distill also supports some advanced field operators:*

- Unset field, array item, hash key
- Merge arrays/hashes
- Immutable ie. prevent a field from being substituted at a lower hierarchy
- Reference other fields

Roadmap
-------
- Write an on-line tutorial with complete examples
- Provide --diff option to changed hosts, that will print a diff for the hosts that has changed configuration
- Rename Expand operator to Reference and implement a Copy operator
- Rewrite in Ruby to enable better Puppet integration (other benefits include degraded performance and memory leaks)
- Inline queries in ERB templates for details like which hosts use module X
- Extend REST API to allow more complicated queries
- MySQL database backend
- Web front-end

Distill Schema
==============
Validate configuration using JSON Schemas.

Description
-----------
Distill Schema is an extension to Distill that allows for the creation of JSON Schemas that can verify a configuration before it's applied to production.

This is usually done as a build step for the templates, using a Build Server like [Jenkins](http://jenkins-ci.org/).

Example
-------

Using the Class mysql::server::user in the above examples for Distill a JSON Schema would look as follows:

*Puppet Class*
<pre>
class mysql::server::user($users)
</pre>

*Distill output as Puppet YAML ENC*
<pre>
  mysql::server::user
    users:
      user1:
        host: %
        password: *6691484EA6B50DDDE1926A220DA01FA9E575C18A
      user2:
        host: %
        password: *6691484EA6B50DDDE1926A220DA01FA9E575C18A
</pre>

*Distill Schema using a JSON Schema*
<pre>
{
    "type": "object",
    "additionalProperties": false,
    "properties": {
        "mysql::server::user": {
            "type": "object",
            "additionalProperties": false,
            "properties": {
                "users": {
                    "type": "object",
                    "patternProperties": {
                        ".*": {
                            "type": "object",
                            "additionalProperties": false,
                            "properties": {
                                "host": {
                                    "type": "string",
                                    "required": true,
                                    "pattern": "^(%|([a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?\\.)+[a-zA-Z]{2,6})$"
                                },
                                "password": {
                                    "type": "string",
                                    "required": true
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
</pre>

Roadmap
-------
- Automatic generation of JSON Schema using template input too provide a starting point
- Allow for defining standardized Regex for known types

Installation
============
Download the Admin Guide PDF inside the *pdfs* directory for instructions.

Links
=====
[JSON Schema RFC](http://tools.ietf.org/html/draft-zyp-json-schema-03)

Related tools
=============
*Hiera*
Hiera is a similar templates engine written in Ruby.
[Hiera](http://projects.puppetlabs.com/projects/hiera/)

*Foreman*
Foreman is a very good front-end to Puppet rather then a template engine.
[Foreman](http://theforeman.org/)

License
=======
See LICENSE file in trunk.
