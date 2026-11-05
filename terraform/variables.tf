############################################
# Credenciais e configuração da API da OCI
# Preenche estes valores em terraform.tfvars
# (nunca commites esse ficheiro — já está no .gitignore)
############################################

variable "tenancy_ocid" {
  description = "OCID da tenancy. Consola: clica no teu perfil (canto superior direito) -> Tenancy, ou Profile menu -> Tenancy: <nome>."
  type        = string
}

variable "user_ocid" {
  description = "OCID do teu utilizador. Consola: Profile icon -> My Profile -> User Information."
  type        = string
}

variable "fingerprint" {
  description = "Fingerprint da tua API key. Consola: My Profile -> API Keys -> (depois de criares a key)."
  type        = string
}

variable "private_key_path" {
  description = "Caminho local para a chave privada .pem gerada ao criares a API key (ex: ~/.oci/oci_api_key.pem)."
  type        = string
}

variable "region" {
  description = "Região OCI onde o laboratório vai correr (ex: eu-frankfurt-1, eu-amsterdam-1, me-jeddah-1)."
  type        = string
  default     = "eu-frankfurt-1"
}

############################################
# Configuração do projecto
############################################

variable "compartment_name" {
  description = "Nome do compartment dedicado ao laboratório."
  type        = string
  default     = "aiops-lab"
}

variable "ssh_public_key" {
  description = "A tua chave pública SSH (conteúdo do ficheiro, ex: ~/.ssh/id_rsa.pub), para acederes à instância."
  type        = string
}

variable "ssh_allowed_cidr" {
  description = "Range de IPs autorizado a aceder por SSH (porta 22) e à interface web do Zabbix (porta 80). Por omissão aberto a todos — restringe ao teu IP assim que possível (ver ADR-007 na Sessão 6)."
  type        = string
  default     = "0.0.0.0/0"
}

variable "instance_shape" {
  description = "Shape da instância Compute. VM.Standard.E2.1.Micro é Always Free em muitas regiões; se não estiver disponível na tua, usa VM.Standard.A1.Flex (ARM, também Always Free)."
  type        = string
  default     = "VM.Standard.E2.1.Micro"
}
