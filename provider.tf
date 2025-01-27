terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
    }
    ansible = {
      source = "ansible/ansible"
      #version = "~> 1.1.0"
    }
  }
  required_version = ">= 0.13"
}

provider "yandex" {
  zone = "ru-central1-b"
}
