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
Infraestrutura Kubernetes da aplicação provisionada com Terraform
