#!/usr/bin/env python

import psycopg2
import sys
import os
from optparse import OptionParser
import json


def parse_options():
    parser = OptionParser(
        usage="%prog -n <host> -i <ipaddr> -g <group>",
        add_help_option=True
    )
    parser.add_option(
        '-n', '--hostname', default=False, dest='host',
        help='Provide hostname for new inventory object'
    )
    parser.add_option(
        '-i', '--ipaddr', default=False, dest='ipaddr',
        help='Provide ip address for host. 32-bitmask only.'
    )
    parser.add_option(
        '-g', '--group', default='managed', dest='group',
        help='Provide group name. Defaults to "managed" unless specified."'
    )
    parser.add_option(
        '-o', '--os', default='', dest='os',
        help='Provide name of OS, if known. Optional arg.'
    )
    parser.add_option(
        '-v', '--version', default='', dest='version',
        help='Provide version of OS, if known. Optional arg.'
    )
    parser.add_option(
        '-u', '--isup', default=True, dest='isup',
        help="Provide the online/offline status as a Boolean."
    )
    parser.add_option(
        '-b', '--oob', default='', dest='oob',
        help='Provide out of band access method, if known.'
    )
    parser.add_option(
        '-x', '-V', '--Verbose', '--verbose', '--xtrace',
        default=False, action='store_true', dest='verbose',
        help='Use this optional argument to deliver xtrace output.'
    )

    return parser


def establish_connection():
    if os.getenv('USER') == 'logos':
        conn = psycopg2.connect('dbname=inventory')
        return conn
    else:
        errmessage = "%s is not 'logos'. Exiting."
        errmessage = errmessage % os.getenv('USER')
        print >> sys.stderr, errmessage
        sys.exit(1)


def clean_args(options, args, parser):
    reqvars = []
    if not options.host:
        reqvars += ['hostname']
    if not options.ipaddr:
        reqvars += ['ipaddr']
    if reqvars:
        parser.print_usage()
        print >> sys.stderr, 'Missing the following mandatory values: '
        for x in reqvars:
            print >> sys.stderr, x
        sys.exit(1)


def check_for_already_existing_values(options, cur):
    cur.execute(
        "SELECT hostname FROM hostnames WHERE hostname = '%s';"
        % options.host
    )
    host_exists = cur.fetchone()
    cur.execute(
        "SELECT ipaddr FROM ipaddrs WHERE ipaddr = '%s/32';"
        % options.ipaddr
    )
    ipaddr_exists = cur.fetchone()
    cur.execute(
        """SELECT hostname,groupname FROM host_groups
        WHERE hostname ='%s'
        AND groupname = '%s';"""
        % (
            options.host,
            options.group
        )
    )
    host_grouping_exists = cur.fetchone()
    retval = {
        'host': host_exists,
        'ipaddr': ipaddr_exists,
        'grouping': host_grouping_exists
    }
    if options.verbose:
        for key, value in retval.items():
            print >> sys.stderr, "WARN: %10s: %-30s" % (key, value)
    for key in retval.keys():
        if retval[key]:
            retval[key] = True
        else:
            retval[key] = False

    return retval


def insert_host(options, cur, existing_values):
    if not existing_values['host']:
        cur.execute(
            "INSERT INTO hostnames (hostname) VALUES ('%s');" %
            options.host
        )
    if not existing_values['ipaddr']:
        cur.execute(
            "INSERT INTO ipaddrs (ipaddr) VALUES ('%s/32');" %
            options.ipaddr
        )
    if not existing_values['grouping']:
        cur.execute(
            """INSERT INTO host_groups (
                 hostname,
                 groupname
               ) VALUES (
                 '%s',
                 '%s'
               );""" %
            (
                options.host,
                options.group
            )
        )
    if not existing_values['host'] and not existing_values['ipaddr']:
        cur.execute(
            """INSERT INTO host_inventory (
                hostname,
                ipaddr,
                online,
                row_is_obsolete,
                os,
                os_version,
                oob_access_method
            ) VALUES (
                '%s',
                '%s',
                %s,
                %s,
                '%s',
                '%s',
                '%s'
            );""" %
            (
                options.host,
                options.ipaddr,
                options.isup,
                'False',
                options.os,
                options.version,
                options.oob
            )
        )


def main():
    parser = parse_options()
    (options, args) = parser.parse_args()
    args = json.dumps(args)

    if options.verbose:
        import xtrace
        xtrace.start()

    conn = establish_connection()
    cur = conn.cursor()

    clean_args(options, args, parser)
    existing_values = check_for_already_existing_values(options, cur)
    insert_host(options, cur, existing_values)
    conn.commit()
    cur.close()


if __name__ == '__main__':
    sys.exit(main())
