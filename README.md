# Base de Alertas de Desmatamento - MapBiomas Alerta

Este repositório contém a base espacial de alertas de desmatamento semanal do MapBiomas Alerta, formatada para uso em uma aplicação Shiny de verificação de sobreposições com imóveis rurais.

## Estrutura

- `/dados/alertas.zip`: Arquivo `.zip` contendo shapefiles com alertas atualizados.

## Atualização Automática

Este repositório é atualizado semanalmente por meio do GitHub Actions, que baixa a versão mais recente dos alertas do MapBiomas e substitui o arquivo zipado.

## Uso na aplicação Shiny

A aplicação Shiny se conecta diretamente a este repositório e faz o download do arquivo `alertas.zip` na primeira vez que é carregada.
