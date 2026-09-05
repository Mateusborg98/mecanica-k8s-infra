# Infraestrutura Kubernetes da Mecânica

Este repositório provisiona o cluster Amazon EKS utilizado pela aplicação
principal do Tech Challenge.

## Recursos

- Amazon EKS;
- Managed Node Group escalável;
- uso da VPC e das subnets padrão do Learner Lab;
- estado remoto do Terraform no S3;
- acesso administrativo associado a uma role preexistente.
- Datadog Agent instalado por Helm para métricas e logs do Kubernetes.

As roles IAM não são criadas pelo Terraform. O AWS Academy restringe a criação
de IAM, por isso os ARNs das roles fornecidas pelo laboratório são recebidos por
variáveis.

## Segurança de acesso

O cluster mantém o endpoint privado para comunicação dentro da VPC e também
expõe o endpoint público para permitir o deploy por runners hospedados do
GitHub Actions. Conhecer o endpoint não concede acesso ao cluster: as chamadas
continuam protegidas por autenticação AWS IAM e autorização do Kubernetes.

No Learner Lab, os IPs dos runners são dinâmicos e o CIDR público é configurado
como `0.0.0.0/0`. Em um ambiente corporativo, a preferência seria utilizar um
runner privado dentro da VPC ou restringir os blocos de rede autorizados.

## Escalabilidade

Em homologação, o Node Group começa com um nó `t3.small` e permite expansão até
dois nós. A quantidade de pods será controlada posteriormente pelo Horizontal
Pod Autoscaler no repositório da aplicação.

## Custo no Learner Lab

O EKS e as instâncias EC2 geram custo enquanto existem. O ambiente deve ser
criado apenas durante validações e destruído ao final da sessão de trabalho.

## Observabilidade com Datadog

O workflow de deploy instala o Datadog Agent no namespace `datadog` depois da
criação do EKS. A configuração versionada está em
`observability/datadog-values.yaml` e habilita:

- métricas de CPU, memória, pods, deployments e nós;
- coleta seletiva dos logs da aplicação por autodiscovery;
- coleta OpenMetrics do endpoint Prometheus da aplicação;
- tags `project:mecanica` e `env:homolog|prod`.

Crie os secrets `DATADOG_API_KEY` e `DATADOG_APP_KEY` nos environments
`homolog` e `production`.
Nenhuma chave é armazenada no repositório. Para o site
`https://app.datadoghq.com`, o valor de `datadog.site` deve permanecer como
`datadoghq.com`.

O diretório `observability/terraform` mantém, em um estado remoto separado, o
dashboard e os alertas de indisponibilidade, falha no processamento de ordens,
latência e CPU. O dashboard apresenta volume diário de ordens, tempo médio por
status, latência das APIs, recursos do Kubernetes e erros das integrações.
CPF/CNPJ, JWT, senhas e chaves não são enviados como logs ou métricas.

Após o deploy, valide a instalação com:

```bash
kubectl get pods -n datadog
kubectl get daemonset -n datadog
helm status datadog-agent -n datadog
```

No Datadog, confirme o cluster `mecanica-homolog`, abra o dashboard
`Mecânica - homolog` e verifique os monitores criados pelo Terraform. Métricas
da aplicação só aparecem depois do deploy de `mecanica-api` e da geração de
tráfego.

## Validação local

```powershell
terraform -chdir=infra init -backend=false
terraform -chdir=infra fmt -check
terraform -chdir=infra validate

terraform -chdir=observability/terraform init -backend=false
terraform -chdir=observability/terraform fmt -check
terraform -chdir=observability/terraform validate
```

O CI também renderiza o Helm Chart do Datadog com uma chave fictícia. Isso
valida a estrutura do arquivo sem enviar dados nem criar recursos.

## CI/CD e configuração do GitHub

```text
feature/* -> Pull Request -> homolog -> Pull Request -> main
```

O CI valida Terraform e Helm em features e Pull Requests. O CD roda depois de
push em `homolog` ou `main`, cria/atualiza o EKS, instala o Datadog Agent e
provisiona o dashboard e os monitores.

Configure nos environments `homolog` e `production`:

| Tipo | Nome | Finalidade |
|---|---|---|
| Secret | `EKS_CLUSTER_ROLE_ARN` | Role preexistente do control plane. |
| Secret | `EKS_NODE_ROLE_ARN` | Role preexistente do Managed Node Group. |
| Secret | `EKS_ADMIN_PRINCIPAL_ARN` | Principal autorizado no cluster. |
| Secret | `DATADOG_API_KEY` | Envio de métricas e logs. |
| Secret | `DATADOG_APP_KEY` | Criação de dashboards e monitores. |
| Secret | `TF_STATE_BUCKET` | Bucket remoto dos states. |
| Secret | `AWS_ACCESS_KEY_ID` | Credencial temporária. |
| Secret | `AWS_SECRET_ACCESS_KEY` | Credencial temporária. |
| Secret | `AWS_SESSION_TOKEN` | Token temporário. |

As roles, o bucket e as chaves Datadog permanecem estáveis. Somente as três
credenciais temporárias AWS são atualizadas em uma nova sessão do Learner Lab.

`main` e `homolog` devem exigir Pull Request e o check `Terraform validation`.

## Encerramento para evitar custos

O EKS não possui operação de pausa. Para interromper a cobrança, ele deve ser
destruído pelo mesmo state usado na criação:

```powershell
terraform -chdir=infra init -reconfigure `
  -backend-config="bucket=<bucket-do-state>" `
  -backend-config="key=mecanica-k8s/homolog/terraform.tfstate" `
  -backend-config="region=us-east-1"

terraform -chdir=infra destroy `
  -var="environment=homolog" `
  -var="cluster_role_arn=<arn-cluster>" `
  -var="node_role_arn=<arn-node>" `
  -var="cluster_admin_principal_arn=<arn-admin>"
```

Revise o plano antes de confirmar. Depois, valide:

```powershell
aws eks describe-cluster --region us-east-1 --name mecanica-homolog
terraform -chdir=infra state list
```

O primeiro comando deve retornar `ResourceNotFoundException`; o state não deve
manter recursos gerenciados do EKS. Os data sources podem continuar listados.
