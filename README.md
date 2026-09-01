# Infraestrutura Kubernetes da Mecânica

Este repositório provisiona o cluster Amazon EKS utilizado pela aplicação
principal do Tech Challenge.

## Recursos

- Amazon EKS;
- Managed Node Group escalável;
- uso da VPC e das subnets padrão do Learner Lab;
- estado remoto do Terraform no S3;
- acesso administrativo associado a uma role preexistente.

As roles IAM não são criadas pelo Terraform. O AWS Academy restringe a criação
de IAM, por isso os ARNs das roles fornecidas pelo laboratório são recebidos por
variáveis.

## Segurança de acesso

O endpoint Kubernetes nasce privado e o acesso administrativo é concedido
somente à role informada. O acesso necessário ao deploy externo será tratado
separadamente, sem deixar o endpoint aberto por padrão.

## Escalabilidade

Em homologação, o Node Group começa com um nó `t3.small` e permite expansão até
dois nós. A quantidade de pods será controlada posteriormente pelo Horizontal
Pod Autoscaler no repositório da aplicação.

## Custo no Learner Lab

O EKS e as instâncias EC2 geram custo enquanto existem. O ambiente deve ser
criado apenas durante validações e destruído ao final da sessão de trabalho.
Infraestrutura Kubernetes da aplicação provisionada com Terraform
