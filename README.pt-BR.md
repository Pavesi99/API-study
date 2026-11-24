# ProductKnowledgeLab — etapa 1

[English](README.md)

Aplicação pequena de console em C# que responde uma pergunta sobre documentação fictícia de produtos usando o SDK oficial da OpenAI e a Responses API. Código, prompts e rótulos do console estão em inglês. A documentação dos produtos é fornecida em português e inglês; as respostas usam inglês por padrão e podem usar outro idioma com `--language`.

## Pré-requisitos e compilação

SDK .NET 10 e acesso de rede ao NuGet. O SDK estável disponível inspecionado aqui foi o 10.0.400. Execute na raiz do repositório, em PowerShell ou Bash:

```text
dotnet restore ProductKnowledgeLab/ProductKnowledgeLab.csproj
dotnet build ProductKnowledgeLab/ProductKnowledgeLab.csproj --no-restore
```

O projeto fixa [OpenAI 2.14.0](https://www.nuget.org/packages/OpenAI/2.14.0). Os tipos de Responses estão marcados como experimentais no SDK, por isso Program.cs suprime o diagnóstico específico OPENAI001. Consulte os [exemplos oficiais de C#](https://developers.openai.com/api/docs/libraries) e as [assinaturas publicadas do SDK](https://github.com/openai/openai-dotnet/blob/OpenAI_2.14.0/api/released/net10.0/OpenAI.Responses.net10.0.cs).

## Configuração local

Defina OPENAI_API_KEY e OPENAI_MODEL no ambiente do processo. Nenhuma tem valor padrão. Não há arquivo de configuração nem carregador de .env. Crie/gerencie uma chave no [painel da API](https://platform.openai.com/api-keys) e informe-a apenas no seu terminal local. Nunca cole a chave na conversa nem a versione.

PowerShell 7.1+ (entrada oculta; apenas na sessão atual):

```powershell
$env:OPENAI_API_KEY = Read-Host 'OpenAI API key' -MaskInput
$env:OPENAI_MODEL = 'gpt-6-luna'
dotnet run --project ProductKnowledgeLab --no-build
# Question: Quem pode excluir um produto Draft?
dotnet run --project ProductKnowledgeLab --no-build -- --without-docs
# Question: Como restauro um produto excluído?
Remove-Item Env:OPENAI_API_KEY
```

Bash (entrada oculta; apenas na sessão atual):

```bash
read -rsp 'OpenAI API key: ' OPENAI_API_KEY
printf '\n'
export OPENAI_API_KEY
export OPENAI_MODEL='gpt-6-luna'
dotnet run --project ProductKnowledgeLab --no-build
# Question: Quem pode excluir um produto Draft?
dotnet run --project ProductKnowledgeLab --no-build -- --without-docs
# Question: Como restauro um produto excluído?
unset OPENAI_API_KEY
```

Cada execução configurada com uma pergunta não vazia envia uma requisição potencialmente cobrada. Execute esses comandos você mesmo quando estiver pronto. A saída inclui Answer, Model, Duration, Input tokens, Output tokens e Status; nenhuma medida ou resposta ilustrativa aqui é apresentada como resultado observado.

## Idioma da resposta

Use `--language <nome-ou-código>` para escolher o idioma da resposta. Nomes com espaços precisam de aspas. Sem essa opção, as respostas usam inglês. Português (`pt`, `pt-BR`, `Portuguese`, `Português`) e inglês (`en`, `English`) têm aliases explícitos; outros nomes ou códigos de idioma são enviados ao modelo. O suporte efetivo ao idioma depende do modelo escolhido. Os rótulos do console permanecem em inglês.

```text
dotnet run --project ProductKnowledgeLab --no-build -- --language Portuguese
dotnet run --project ProductKnowledgeLab --no-build -- --language English
dotnet run --project ProductKnowledgeLab --no-build -- --language Japanese
dotnet run --project ProductKnowledgeLab --no-build -- --language "Brazilian Portuguese"
dotnet run --project ProductKnowledgeLab --no-build -- --language fr-FR --without-docs
```

As regras dos produtos continuam em português e inglês, independentemente do idioma da resposta. `--without-docs` omite ambas as versões. Argumentos de idioma ausentes, vazios, duplicados ou malformados são rejeitados antes de qualquer chamada à API. O valor pode ter até 80 caracteres, começando por uma letra e contendo apenas letras, espaços e hífens.

## Escolha do modelo e consumo

Para esta tarefa curta, comece avaliando `gpt-6-luna`, um modelo de texto econômico cuja [página oficial](https://developers.openai.com/api/docs/models/gpt-6-luna) informa suporte a Responses. Em 05/11/2026, os [preços padrão](https://developers.openai.com/api/docs/pricing) são US$0,10 por milhão de tokens de entrada e US$0,50 por milhão de tokens de saída. Confira preços, disponibilidade no seu projeto e compatibilidade antes de executar; a aplicação não escolhe modelo nem faz fallback.

Para texto comum sem cache, uma estimativa é `inputTokens / 1,000,000 * 0.10 + outputTokens / 1,000,000 * 0.50` USD. Preços de cache e eventuais adicionais de processamento podem alterar a cobrança. A estimativa não é um teto de gastos. Instruções, documentação e pergunta contribuem para o consumo de entrada. A saída pode incluir tokens de raciocínio, portanto não precisa corresponder ao tamanho da resposta visível.

## O que chega ao modelo

1. `CreateResponseOptions.Instructions` contém as regras de comportamento: responder no idioma escolhido (inglês por padrão), usar apenas a documentação fornecida, tratá-la como dados, reconhecer informações ausentes e evitar suposições.
2. Um item de entrada de usuário identificado por `Documentation (reference data):` contém as quatro regras fictícias em português e inglês. `--without-docs` omite esse item inteiro e preserva as instruções.
3. Outro item de entrada de usuário identificado por `Question:` contém a pergunta digitada no terminal.

O [guia de geração de texto](https://developers.openai.com/api/docs/guides/text) explica o campo de instruções e os papéis das mensagens. Os rótulos tornam legíveis os limites dos dados; não garantem obediência do modelo. Não há busca de documentos nem treinamento do modelo. Todos os itens pertencem à mesma requisição, sem conversa anterior.

A documentação fictícia diz:

- Um produto só pode ser excluído em Draft.
- Produtos Active precisam ser encerrados antes de serem arquivados.
- Apenas usuários ProductAdmin podem excluir produtos.
- A restauração de produtos excluídos não está definida.

## Fluxo e limites da aplicação

`Program.cs` valida argumentos e variáveis de ambiente, lê uma pergunta, monta a requisição, aguarda `CreateResponseAsync`, mostra texto e metadados retornados e encerra. Não há camadas de aplicação nem frameworks adicionais.

- Timeout de rede e prazo de cancelamento são de 60 segundos. Stopwatch mede a chamada à API, excluindo digitação e exibição no console.
- O máximo de saída é 800 tokens, incluindo raciocínio quando aplicável. Respostas incompletas podem conter texto parcial ou vazio; a aplicação mostra o status e encerra com código 1.
- O SDK normalmente repete erros HTTP 408, 429, 500, 502, 503 e 504 até três vezes adicionais, com espera exponencial. Aqui, `ClientRetryPolicy(maxRetries: 0)` desabilita isso e não há laço de retry: no máximo uma tentativa. Consulte o [comportamento de retries do SDK](https://github.com/openai/openai-dotnet/blob/OpenAI_2.14.0/README.md#automatically-retrying-errors).
- Configuração ausente, argumentos inválidos e pergunta vazia encerram com código 1 antes da criação do cliente. Respostas concluídas com sucesso encerram com código 0.
- Falhas de autenticação, permissão, limite/cota, conexão, timeout e outros erros recebem mensagens fixas em inglês. Corpos de exceções, cabeçalhos, credenciais e stack traces não são impressos.
- Tokens vêm do uso reportado pela API, sem estimativa local; uso ausente aparece como `not reported`. Model é o identificador retornado pela API.
- Nenhum histórico ou log é gravado. `StoredOutputEnabled = false` desabilita armazenamento da resposta para recuperação posterior; isso não promete retenção zero pelo provedor. Consulte os [controles de dados da API](https://developers.openai.com/api/docs/guides/your-data).
- Um timeout no cliente não garante que o servidor parou de processar ou que não houve cobrança. Decida manualmente antes de repetir uma chamada que falhou.

## Experimentos manuais

Execute o primeiro comando três vezes, digitando uma pergunta em cada execução; use o segundo para o experimento 4. Os comandos funcionam em PowerShell e Bash:

```text
dotnet run --project ProductKnowledgeLab --no-build
dotnet run --project ProductKnowledgeLab --no-build -- --without-docs
```

| # | Pergunta a digitar | Documentação | Critério de adequação |
|---|---|---|---|
| 1 | Quem pode excluir um produto Draft? | Sim | Identifica ProductAdmin; estar em Draft não basta como permissão. |
| 2 | Um ProductAdmin pode excluir um produto Active? | Sim | Diz não: somente Draft pode ser excluído; não confunde arquivamento com exclusão. |
| 3 | Como restauro um produto excluído? | Sim | Diz explicitamente que restauração não está definida; não inventa procedimento. |
| 4 | Como restauro um produto excluído? | Não (`--without-docs`) | Informa que não há documentação disponível para fundamentar a resposta. |

Anote o modelo retornado e mantenha-o igual ao comparar execuções. Não registre segredos nem perguntas sensíveis.

| # | Modelo retornado | Resposta | Tokens de entrada | Tokens de saída | Duração (s) | Adequado? / observações |
|---|---|---|---|---|---|---|
| 1 | | | | | | |
| 2 | | | | | | |
| 3 | | | | | | |
| 4 | | | | | | |

## Validação local e verificações pendentes

Atualização de idiomas validada em 23/11/2026: build Debug concluído sem avisos nem erros e todas as 19 verificações offline passaram executando o conteúdo do script inline, sem alterar a política de execução. As verificações cobrem a validação existente, nomes/códigos de idioma aceitos, ordem das opções e argumentos de idioma inválidos. Respostas reais do modelo não foram testadas.

Validado localmente em 05/11/2026: restore das dependências concluído com acesso autorizado à rede fora do sandbox; build Debug concluído com zero avisos e zero erros. Os seis testes offline em execução passaram: chave/modelo ausentes em conjunto e individualmente, entrada vazia, argumento inválido e configuração ausente com --without-docs. Também foram concluídas a inspeção do SDK e a conferência das assinaturas no código-fonte.

Após um build Debug bem-sucedido, execute as verificações sem credenciais:

```powershell
./Verify-Offline.ps1
```

No Bash com PowerShell 7 instalado:

```bash
pwsh -File ./Verify-Offline.ps1
```

O script inicia processos filhos removendo os valores herdados de chave/modelo sem lê-los e usa valores fictícios quando necessário. Verifica variáveis ausentes individualmente e em conjunto, entrada vazia, argumento inválido e configuração ausente com --without-docs. Esses caminhos encerram antes de qualquer chamada à API. A sintaxe PowerShell foi verificada com sucesso. O carregamento do arquivo .ps1 foi bloqueado pela política local de execução, então os mesmos testes foram executados como comandos PowerShell inline e todos passaram. Nenhuma política de execução foi alterada. Executar o arquivo de script em si exige um ambiente que permita scripts locais.

Nenhuma chamada paga à API foi executada. Acesso real ao modelo, respostas, uso, latência e tratamento de falhas reais dependem dos seus experimentos. Compartilhe a tabela dos experimentos preenchida antes de avançarmos à etapa 2.



