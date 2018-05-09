#!/bin/env python

import boto3
import json
import sys
import dns.resolver
import socket
import logging
import os

rawconfig = open('example_aws_cluster_dns_config.json', 'r').read()
config = json.loads(rawconfig)

logger = logging.getLogger(__file__)
if os.environ.get('LOGLEVEL') is not None:
    logging.basicConfig(level=os.environ.get("LOGLEVEL"))
    loglevel=os.environ.get("LOGLEVEL")
else:
    loglevel=logging.WARN

logger.setLevel(loglevel)

ch = logging.StreamHandler()
ch.setLevel(loglevel)

formatter = logging.Formatter('%(asctime)s - %(name)s - %(levelname)s - %(message)s')
ch.setFormatter(formatter)
logger.addHandler(ch)

client = boto3.client('route53')


class data:
    zone_id = 'Default'
    prodint_name = 'Default'
    node_a_records = {
        'env-node1': ['rr_obj'],
        'env-node2': ['rr_obj']
    }
    rrdns_a_records = ['rr_obj', 'rr_obj']
    update_response = 'json_obj'


def obtain_hosted_zone():
    hosted_zones = client.list_hosted_zones()
    hosted_zones = hosted_zones["HostedZones"]

    data.hosted_zones = hosted_zones


def obtain_prodint_zone():
    data.prodint_zone = None
    zone = config['basic']['zone']
    for hosted_zone in data.hosted_zones:
        if zone in hosted_zone["Name"]:
            data.prodint_zone =  hosted_zone

    if data.prodint_zone == None:
        message = "%s zone not found."  % config['basic']['zone']
        logger.error(message)


def obtain_a_records():
    node_answers = {}
    rrdns_answers = []
    zone = config['basic']['zone']
    rrdns_name = config['basic']['rrdns-name']
    for node in config['nodes']:
        node_answers[node] = dns.resolver.query( node + "." + zone , 'A')
    data.node_answers = node_answers

    rrdns_answers = dns.resolver.query( rrdns_name + "." + zone, 'A')
    data.rrdns_answers = rrdns_answers


def define_some_variables():
    obtain_hosted_zone()
    obtain_prodint_zone()
    data.zone_id = data.prodint_zone['Id']
    data.prodint_name = data.prodint_zone['Name']

    obtain_a_records()

    data.node_a_records = {}
    for key,value in data.node_answers.items():
        data.node_a_records[key] = [ x for x in value.rrset ]

    data.rrdns_a_records = [ x for x in data.rrdns_answers.rrset ]


def try_ports(host_tuple,message):
    try:
        sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        sock.connect(host_tuple)
        sock.sendall(message)

        amount_received = 0
        amount_expected = len(message)
        tcp_data = None

        while amount_received < amount_expected:
            tcp_data = sock.recv(16)
            amount_received += len(tcp_data)

        return tcp_data

    except Exception as e:
        print e
    finally:
        sock.close()


def check_tcp_ports():
    message = config['tcp']['message']
    port = config['tcp']['port']
    zone = config['basic']['zone']
    tcp_addresses = {}
    for node in config['nodes']:
        fqdn = node + "." + config['basic']['zone']
        tcp_addresses[node] = ( node + "." + zone, port )
    tcp_check_results = {}
    for hostname,host_tuple in tcp_addresses.items():
        tcp_check_results[hostname] = try_ports(host_tuple,message)

    data.tcp_check_results = tcp_check_results


def compare_a_results():
    data.a_results = {}

    for node,node_record in data.node_a_records.items():
        if node_record[0] in data.rrdns_a_records:
            data.a_results[node] = True

    info_message = "A_RECORD_COMPARISON:  %s ::: %s"  % (data.node_a_records, data.a_results)
    logger.info(info_message)

    if data.a_results.keys() == data.node_a_records.keys():
        logger.info("ALL A RECORDS CURRENTLY PRESENT")


def compare_tcp_results():
    data.tcp_results = {}
    check_tcp_ports()

    info_message = "tcp_check_results: %s" % ( data.tcp_check_results)
    logger.info(info_message)

    result = config['tcp']['result']

    for node,check_result in data.tcp_check_results.items():
        if result in check_result:
            data.tcp_results[node] = True


def dns_update(dns_action, dns_name, dns_type, dns_ttl, dns_records):
    try:
        data.update_response = client.change_resource_record_sets(
            HostedZoneId=data.zone_id,
            ChangeBatch={
                'Comment': 'Automated revision of change1.prod.int.mojo.live.',
                'Changes': [
                    {
                        'Action': dns_action,
                        'ResourceRecordSet': {
                            'Name': dns_name,
                            'Type': dns_type,
                            'TTL': dns_ttl,
                            'ResourceRecords': dns_records
                        }
                    }
                ]
            }
        )
    except Exception as e:
        print e


def set_dns_to_new_values(new_values):
    dns_update(
        'UPSERT',
        config['basic']['rrdns-name'] + "." + config['basic']['zone'],
        'A',
        300,
        new_values
    )


def update_dns_if_necessary():
    if data.a_results == data.tcp_results:
        logger.info("No DNS change Necessary.")
        return 0
    else:
        new_values = []
        for node,value in data.tcp_results.items():
            if value == True:
                new_values.append(config['dns-values'][node])
        if new_values == []:
            logger.error("ERROR: All hosts failed tcp port check.")
            return 1
        set_dns_to_new_values(new_values)
	logger.info(data.update_response)


def main():
    define_some_variables()
    logger.info(data.prodint_name)

    compare_a_results()
    a_record_message = "A Records: %s"  % data.a_results
    logger.info(a_record_message)

    compare_tcp_results()
    tcp_check_message = "TCP Checks: %s"  % data.tcp_results
    logger.info(tcp_check_message)

    update_retval = update_dns_if_necessary()
    return update_retval


if __name__ ==  "__main__":
    sys.exit(main())
