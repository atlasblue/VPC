#################################################
#################################################
#              DEVELOPMENT ENVIRONMENT          #
#################################################

#################################################
# CREATE VPC
#################################################

resource "nutanix_vpc" "vpc_dev" {
  name = "VPC DEV"
  external_subnet_reference_name = [
    var.EXTERNAL_SUBNET
  ]
}

#################################################
# CREATE DEFAULT ROUTE
#################################################
data "nutanix_subnet" "external_subnet" {
  subnet_name = var.EXTERNAL_SUBNET
}
resource "nutanix_static_routes" "static_routes" {
  vpc_name = "VPC DEV"
  default_route_nexthop {
    external_subnet_reference_uuid = data.nutanix_subnet.external_subnet.id
  }
  depends_on = [nutanix_vpc.vpc_dev]
}
  
#################################################
# CREATE OVERLAY SUBNET FOR WEB TIER
#################################################

resource "nutanix_subnet" "LS-Web-Dev" {
  name        = "LS WEB DEV"
  subnet_type                = "OVERLAY"
  subnet_ip                  = "192.168.1.0"
  prefix_length              = 24
  default_gateway_ip         = "192.168.1.1"
  ip_config_pool_list_ranges = ["192.168.1.10 192.168.1.20"]
  dhcp_domain_name_server_list = ["8.8.8.8"]
  vpc_reference_uuid = nutanix_vpc.vpc_dev.metadata.uuid 
  depends_on = [
    nutanix_vpc.vpc_dev
  ]
}
#################################################
# CREATE OVERLAY SUBNET FOR DB TIER
#################################################

resource "nutanix_subnet" "LS-DB-Dev" {
	name = "LS DB DEV"
	subnet_type = "OVERLAY"
	subnet_ip = "192.168.2.0"
	prefix_length = 24
	default_gateway_ip = "192.168.2.1"
	ip_config_pool_list_ranges = ["192.168.2.10 192.168.2.20"]
	dhcp_domain_name_server_list = ["8.8.8.8"]
	vpc_reference_uuid = nutanix_vpc.vpc_dev.metadata.uuid 
	depends_on = [
		nutanix_vpc.vpc_dev
	]
}

#################################################
# CREATE VM DB
#################################################

resource "nutanix_image" "centos7" {
  name = "centos7"
  source_uri  = "http://download.nutanix.com/Calm/Centos7-Base.qcow2"
  description = "centos 7 image"
}

resource "nutanix_virtual_machine" "vm_db_dev" {
  name                 = "DB-DEV"
  num_vcpus_per_socket = 1
  num_sockets          = 1
  memory_size_mib      = 2048
  cluster_uuid         = local.cluster1
  guest_customization_cloud_init_user_data = filebase64("./cloudinit.yaml")

  nic_list {
    subnet_uuid = nutanix_subnet.LS-DB-Dev.id
    ip_endpoint_list  {
            ip = "192.168.2.10"
            type = "ASSIGNED"
        } 
  }

  disk_list {
    data_source_reference = {
      kind = "image"
      uuid = nutanix_image.centos7.id
    }
    device_properties {
      disk_address = {
        device_index = 0
        adapter_type = "SCSI"
      }

      device_type = "DISK"
    }
  }
  disk_list {
    disk_size_mib   = 100000
    disk_size_bytes = 104857600000
  }

  disk_list {
    disk_size_bytes = 0

    data_source_reference = {}

    device_properties {
      device_type = "CDROM"
      disk_address = {
        device_index = "1"
        adapter_type = "SATA"
      }
    }
  }
  depends_on = [nutanix_subnet.LS-DB-Dev]
}

#################################################
# CREATE FLOATING IP FOR VM DB
#################################################

resource "nutanix_floating_ip" "fip_vm_db" {
  external_subnet_reference_name = var.EXTERNAL_SUBNET
  vm_nic_reference_uuid = nutanix_virtual_machine.vm_db_dev.nic_list[0].uuid
  depends_on = [
    nutanix_virtual_machine.vm_db_dev
  ]
}

#################################################
# GET FLOATING IP FOR VM DB
#################################################

data "nutanix_floating_ip" "fip_vm_db"{
    floating_ip_uuid = resource.nutanix_floating_ip.fip_vm_db.id
  }

#################################################
# DATABASE INSTALLATION AND CONFIGURATION
#################################################

resource "null_resource" "installdb" {
  
  connection {
        type     = "ssh"
        host     = data.nutanix_floating_ip.fip_vm_db.status[0].resources[0].floating_ip
        user     = "root"
        password = "nutanix/4u"
      }  
  provisioner "file" {
        source = "./fiesta-db.sh" 
        destination = "/fiesta-db.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo chmod +x /fiesta-db.sh",
      "sh /fiesta-db.sh",
    ]
    
   }
  
depends_on = [nutanix_floating_ip.fip_vm_db]
}


#################################################
# CREATE VM WEB
#################################################

resource "nutanix_virtual_machine" "vm_web_dev" {
  name                 = "WEB-DEV"
  num_vcpus_per_socket = 1
  num_sockets          = 1
  memory_size_mib      = 2048
  cluster_uuid         = local.cluster1
  guest_customization_cloud_init_user_data = filebase64("./cloudinit.yaml")
  nic_list {
    subnet_uuid = nutanix_subnet.LS-Web-Dev.id
    ip_endpoint_list  {
            ip = "192.168.1.10"
            type = "ASSIGNED"
        } 
  }
  disk_list {
    data_source_reference = {
      kind = "image"
      uuid = nutanix_image.centos7.id
    }
    device_properties {
      disk_address = {
        device_index = 0
        adapter_type = "SCSI"
      }

      device_type = "DISK"
    }
  }
  disk_list {
    disk_size_mib   = 100000
    disk_size_bytes = 104857600000
  }

  disk_list {
    disk_size_bytes = 0

    data_source_reference = {}

    device_properties {
      device_type = "CDROM"
      disk_address = {
        device_index = "1"
        adapter_type = "SATA"
      }
    }
  }
  depends_on = [nutanix_virtual_machine.vm_db_dev]
}


#################################################
# CREATE FLOATING IP FOR VM WEB
#################################################

resource "nutanix_floating_ip" "fip_vm_web" {
  external_subnet_reference_name = var.EXTERNAL_SUBNET
  vm_nic_reference_uuid = nutanix_virtual_machine.vm_web_dev.nic_list[0].uuid
  depends_on = [
    nutanix_virtual_machine.vm_web_dev
  ]
}

#################################################
# GET FLOATING IP FOR VM DB
#################################################

data "nutanix_floating_ip" "fip_vm_web"{
    floating_ip_uuid = resource.nutanix_floating_ip.fip_vm_web.id
  }

#################################################
# WEBSERVER INSTALLATION AND CONFIGURATION
#################################################

resource "null_resource" "installweb" {
  connection {
        type     = "ssh"
        host     = data.nutanix_floating_ip.fip_vm_web.status[0].resources[0].floating_ip
        user     = "root"
        password = "nutanix/4u"
      }  
  provisioner "file" {
        source = "./fiesta-web.sh" 
        destination = "/fiesta-web.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo chmod +x /fiesta-web.sh",
      #"sed -i 's/VM-DB-IP/${nutanix_virtual_machine.vm_db_dev.nic_list_status[0].ip_endpoint_list[0].ip}/g' fiesta-web.sh",
      "sh /fiesta-web.sh ${nutanix_virtual_machine.vm_db_dev.nic_list_status[0].ip_endpoint_list[0].ip}",
    ]
    
   }
  
depends_on = [nutanix_floating_ip.fip_vm_web]
}

output "WebServer-Development-Floating-IP" {
  value = data.nutanix_floating_ip.fip_vm_web.status[0].resources[0].floating_ip
}
