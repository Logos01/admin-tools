#!/usr/bin/python

import psycopg2
import sys
import simplejson as json
from optparse import OptionParser


def establish_connection():
    global conn
    dbname = 'inventory'
    username = 'username'
    hostname = '127.0.0.1'
    password = 'password'
    connection = "dbname='%s' user='%s' host='%s' password='%s'"
    connection = connection % (
        dbname,
        username,
        hostname,
        password,
    )
    try:
        conn = psycopg2.connect(connection)
        return conn
    except:
        errstring = 'Could not connect to inventory database. Exiting.'
        print >> sys.stderr, errstring
        sys.exit(1)


def obtain_data():
    conn = establish_connection()
    cur = conn.cursor()
    cur.execute('SELECT name, parent FROM groups')
    groups = cur.fetchall()
    cur.execute('SELECT hostname, groupname FROM host_groups')
    host_groups = cur.fetchall()
    cur.execute('SELECT groupname, var_name, var_value FROM group_vars')
    group_vars = cur.fetchall()
    cur.execute('SELECT hostname, ipaddr, in_dns from host_inventory')
    host_inventory = cur.fetchall()
    return (groups, host_groups, group_vars, host_inventory)


def convert_groups(groups, host_groups, ansible_items):
    for x in groups:
        if not x[0] in ansible_items.keys():
            ansible_items[x[0]] = []

    for x in groups:
        for triplet in host_groups:
            if x[0] in triplet:
                ansible_items[x[0]] += [triplet[0], ]

    for x in groups:
        if x[1] in ansible_items.keys():
            ansible_items[x[1]] += ansible_items[x[0]]


def parse_group_vars(group_vars, parsed_group_vars, ansible_items):
    for x in group_vars:
        try:
            parsed_group_vars[x[0]][x[1]] = x[2]
        except:
            parsed_group_vars[x[0]] = {}
            parsed_group_vars[x[0]][x[1]] = x[2]

    for key, value in ansible_items.items():
        ansible_items[key] = {}
        ansible_items[key]['hosts'] = value
        try:
            ansible_items[key]['vars'] = parsed_group_vars[key]
        except KeyError:
            ansible_items[key]['vars'] = {'Null': 'Null'}


def convert_sql_to_dict(groups, host_groups, group_vars, host_inventory):
    ansible_items = {}
    parsed_group_vars = {}

    convert_groups(groups, host_groups, ansible_items)
    parse_group_vars(group_vars, parsed_group_vars, ansible_items)

    return ansible_items


def parse_options():
    parser = OptionParser(
        usage="%prog [options] --list | --host <machine>"
    )
    parser.add_option(
        '--list', default=False, dest="list", action="store_true",
        help="Produce a JSON consumable grouping of servers for Ansible"
    )
    parser.add_option(
        '--host', default=None, dest="host",
        help="Generate additional details for given host for Ansible"
    )
    parser.add_option(
        '-H', '--human', dest="human",
        default=False, action="store_true",
        help="Produce friendlier version of either server list or host detail"
    )
    return parser


def options_list(options, ansible_items):
    if options.human:
        for key in ansible_items.keys():
            print '[%s]\n%s\n' % \
                (key, '\n'.join(ansible_items[key]['hosts']))
    else:
        print json.dumps(ansible_items)


def options_host(options, host_inventory, ansible_items):
    vars = {}
    for group in ansible_items.keys():
        if options.host in ansible_items[group]['hosts']:
            for vkey, vval in ansible_items[group]['vars'].items():
                vars[vkey] = vval
        else:
            vars['Null'] = 'Null'

    for host_details in host_inventory:
        if options.host in host_details[0]:
            vars['ansible_ssh_host'] = host_details[1].replace('/32', '')

    if options.human:
        print 'Host: %s' % (options.host, )
        for key, value in vars.items():
            print '%s: "%s"' % (key, value)
    else:
        print json.dumps(vars)


def main():
    parser = parse_options()
    global options
    (options, args) = parser.parse_args()

    (
        groups,
        host_groups,
        group_vars,
        host_inventory
    ) = obtain_data()
    ansible_items = convert_sql_to_dict(
        groups,
        host_groups,
        group_vars,
        host_inventory
    )

    if options.list:
        options_list(options, ansible_items)

    elif options.host:
        options_host(options, host_inventory, ansible_items)


if __name__ == '__main__':
    sys.exit(main())
