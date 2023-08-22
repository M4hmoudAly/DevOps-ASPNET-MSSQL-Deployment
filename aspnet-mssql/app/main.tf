# Define the AWS provider with the region set to "us-west-2"
provider "aws" {
  region = "us-west-2"  
}

# Define the Kubernetes provider with the kubeconfig file path set to "/k8s/kubeconfig"
provider "kubernetes" {
  config_path = "/k8s/kubeconfig"
}

# Variable to store the domain name
variable "domain_name" {
  default = "godaddy.com"
}

# Create an AWS Route53 hosted zone with the specified domain name
resource "aws_route53_zone" "main" {
  name = var.domain_name
}

# Create an AWS Route53 record for the web application, aliasing it to the Kubernetes Load Balancer
resource "aws_route53_record" "web_app" {
  zone_id = aws_route53_zone.main.zone_id
  name    = var.domain_name
  type    = "A"
  alias {
    name                   = kubernetes_service.web_service.load_balancer_ingress[0].hostname
    zone_id                = kubernetes_service.web_service.load_balancer_ingress[0].zone_id
    evaluate_target_health = true
  }
}

# Create an AWS ACM certificate for the specified domain using DNS validation
resource "aws_acm_certificate" "godaddy" {
  domain_name       = var.domain_name
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

# Validate the AWS ACM certificate using Route53 DNS validation
resource "aws_acm_certificate_validation" "godaddy" {
  certificate_arn         = aws_acm_certificate.godaddy.arn
  validation_record_fqdns = [aws_route53_record.web_app.fqdn]
}

# Create an AWS security group for EC2 instances with SSH and web application traffic allowed
resource "aws_security_group" "instance_security_group" {
  name_prefix = "instance-security-group-"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = var.services.web.ports[0]
    to_port     = var.services.web.ports[0]
    protocol    = "tcp"
    security_groups = [kubernetes_service.web_service.spec[0].provider.aws_security_group_rule.web_lb.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Variable block to define service configurations for the web and db services
variable "services" {
  default = {
    web = {
      build = "app/aspnetapp"
      ports = ["80"]
    }
    db = {
      environment = {
        ACCEPT_EULA  = "Y"
        SA_PASSWORD = "example_123"
      }
      image = "mcr.microsoft.com/azure-sql-edge:1.0.4"
      
    }
  }
}

# Create a Kubernetes namespace named "my-namespace"
resource "kubernetes_namespace" "my_namespace" {
  metadata {
    name = "my-namespace" 
  }
}

# Create a Kubernetes deployment for the web application
resource "kubernetes_deployment" "web_deployment" {
  metadata {
    name      = "web"
    namespace = kubernetes_namespace.my_namespace.metadata[0].name
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "web"
      }
    }

    template {
      metadata {
        labels = {
          app = "web"
        }
      }

      spec {
        container {
          name  = "web"
          image = var.services.web.image
          ports {
            container_port = var.services.web.ports[0]
          }
        
        }
      }
    }
  }
}

# Create a Kubernetes LoadBalancer service for the web application
resource "kubernetes_service" "web_service" {
  metadata {
    name      = "web"
    namespace = kubernetes_namespace.my_namespace.metadata[0].name
  }

  spec {
    selector = {
      app = "web"
    }

    port {
      port        = var.services.web.ports[0]
      target_port = var.services.web.ports[0]
    }
    type = "LoadBalancer"
  }
  metadata {
    annotations = {
            # Use the AWS ACM certificate for SSL termination
      "service.beta.kubernetes.io/aws-load-balancer-ssl-cert" = aws_acm_certificate.godaddy.arn

            # Use HTTP as the backend protocol for the load balancer
      "service.beta.kubernetes.io/aws-load-balancer-backend-protocol" = "http"

            # Specify HTTPS as the SSL port for the load balancer
      "service.beta.kubernetes.io/aws-load-balancer-ssl-ports" = "https"
    }
  }

    # Use the AWS provider for this specific resource, overriding the default region
  provider "aws" {
    region = "us-west-2"
  }


}

# Create an AWS security group rule to allow web application traffic from the Kubernetes Load Balancer
 resource "aws_security_group_rule" "web_lb" {
    type        = "ingress"
    from_port   = var.services.web.ports[0]
    to_port     = var.services.web.ports[0]
    protocol    = "tcp"
    security_group_id = aws_security_group.instance_security_group.id
  }

# Create a Kubernetes deployment for the database
resource "kubernetes_deployment" "db_deployment" {
  metadata {
    name      = "db"
    namespace = kubernetes_namespace.my_namespace.metadata[0].name
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "db"
      }
    }

    template {
      metadata {
        labels = {
          app = "db"
        }
      }

      spec {
        container {
          name  = "db"
          image = var.services.db.image
          ports {
            container_port = var.services.db.ports[0]
          }
         
        }
      }
    }
  }
}

# Create a Kubernetes service for the database
resource "kubernetes_service" "db_service" {
  metadata {
    name      = "db"
    namespace = kubernetes_namespace.my_namespace.metadata[0].name
  }

  spec {
    selector = {
      app = "db"
    }

    port {
      port        = var.services.db.ports[0]
      target_port = var.services.db.ports[0]
    }
  }
}
