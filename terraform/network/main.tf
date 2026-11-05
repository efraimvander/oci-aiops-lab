terraform {
  required_providers {
    oci = {
      source = "oracle/oci"
    }
  }
}
############################################
# Sessão 1 — Infra-estrutura como Código
# VCN, sub-rede pública, gateways e security list
############################################

resource "oci_core_vcn" "aiops_vcn" {
  compartment_id = var.compartment_id
  cidr_blocks    = ["10.0.0.0/16"]
  display_name   = "aiops-vcn"
  dns_label      = "aiopsvcn"
}

resource "oci_core_internet_gateway" "igw" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.aiops_vcn.id
  display_name   = "aiops-igw"
  enabled        = true
}

resource "oci_core_route_table" "public_rt" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.aiops_vcn.id
  display_name   = "aiops-public-rt"

  route_rules {
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_internet_gateway.igw.id
  }
}

resource "oci_core_security_list" "public_sl" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.aiops_vcn.id
  display_name   = "aiops-public-sl"

  egress_security_rules {
    destination = "0.0.0.0/0"
    protocol    = "all"
  }

  # SSH
  ingress_security_rules {
    protocol = "6" # TCP
    source   = var.ssh_allowed_cidr
    tcp_options {
      min = 22
      max = 22
    }
  }

  # Interface web do Zabbix (zabbix-appliance expõe o frontend na porta 80)
  ingress_security_rules {
    protocol = "6"
    source   = var.ssh_allowed_cidr
    tcp_options {
      min = 80
      max = 80
    }
  }

  # ICMP para diagnóstico (ping, path MTU)
  ingress_security_rules {
    protocol = "1" # ICMP
    source   = "0.0.0.0/0"
  }
}

resource "oci_core_subnet" "public_subnet" {
  compartment_id             = var.compartment_id
  vcn_id                     = oci_core_vcn.aiops_vcn.id
  cidr_block                 = "10.0.1.0/24"
  display_name               = "aiops-public-subnet"
  dns_label                  = "public"
  route_table_id             = oci_core_route_table.public_rt.id
  security_list_ids          = [oci_core_security_list.public_sl.id]
  prohibit_public_ip_on_vnic = false
}

