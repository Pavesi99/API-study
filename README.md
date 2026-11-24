# ProductKnowledgeLab — stage 1

[Português brasileiro](README.pt-BR.md)

A small C# console application that answers one question about fictional product documentation using the official OpenAI SDK and the Responses API. Code, prompts, and console labels are in English. Product documentation is supplied in Portuguese and English; answers default to English and can use another language with `--language`.

## Requirements and build

.NET 10 SDK and network access to NuGet. The available stable SDK inspected here was 10.0.400. Run from the repository root in either PowerShell or Bash:

```text
dotnet restore ProductKnowledgeLab/ProductKnowledgeLab.csproj
dotnet build ProductKnowledgeLab/ProductKnowledgeLab.csproj --no-restore
```

The project pins [OpenAI 2.14.0](https://www.nuget.org/packages/OpenAI/2.14.0). Its Responses types are marked experimental by the SDK, so Program.cs suppresses the specific diagnostic OPENAI001. See the [official C# examples](https://developers.openai.com/api/docs/libraries) and the [published SDK API surface](https://github.com/openai/openai-dotnet/blob/OpenAI_2.14.0/api/released/net10.0/OpenAI.Responses.net10.0.cs).

## Local configuration

Set both OPENAI_API_KEY and OPENAI_MODEL in the process environment. Neither has a default. No configuration file or .env loader is used. Create/manage a key in the [API dashboard](https://platform.openai.com/api-keys), and enter it only in your local terminal. Never paste it into chat or commit it.

PowerShell 7.1+ (hidden input; only the current session):

```powershell
$env:OPENAI_API_KEY = Read-Host 'OpenAI API key' -MaskInput
$env:OPENAI_MODEL = 'gpt-5.4-mini'
dotnet run --project ProductKnowledgeLab --no-build
# Question: Quem pode excluir um produto Draft?
dotnet run --project ProductKnowledgeLab --no-build -- --without-docs
# Question: Como restauro um produto excluído?
Remove-Item Env:OPENAI_API_KEY
```

Bash (hidden input; only the current session):

```bash
read -rsp 'OpenAI API key: ' OPENAI_API_KEY
printf '\n'
export OPENAI_API_KEY
export OPENAI_MODEL='gpt-5.4-mini'
dotnet run --project ProductKnowledgeLab --no-build
# Question: Quem pode excluir um produto Draft?
dotnet run --project ProductKnowledgeLab --no-build -- --without-docs
# Question: Como restauro um produto excluído?
unset OPENAI_API_KEY
```

Each configured execution with a non-empty question sends one potentially billable request. Run these commands yourself when ready. The output includes Answer, Model, Duration, Input tokens, Output tokens, and Status; no example measurements or model answers here are claimed as observed.

## Answer language

Use `--language <name-or-code>` to choose the answer language. Names containing spaces must be quoted. Without this option, answers use English. Portuguese (`pt`, `pt-BR`, `Portuguese`, `Português`) and English (`en`, `English`) have explicit aliases; other language names or codes are passed to the model. Actual language support depends on the selected model. Console labels remain in English.

```text
dotnet run --project ProductKnowledgeLab --no-build -- --language Portuguese
dotnet run --project ProductKnowledgeLab --no-build -- --language English
dotnet run --project ProductKnowledgeLab --no-build -- --language Japanese
dotnet run --project ProductKnowledgeLab --no-build -- --language "Brazilian Portuguese"
dotnet run --project ProductKnowledgeLab --no-build -- --language fr-FR --without-docs
```

The supplied product rules remain in both Portuguese and English regardless of the answer language. `--without-docs` omits both versions. Missing, blank, duplicate, or malformed language arguments are rejected before any API call. Language values can contain up to 80 characters, starting with a letter and using only letters, spaces, and hyphens.

## Choosing a model and understanding consumption

For this short task, start by evaluating `gpt-6-luna`, an economical text model whose [official model page](https://developers.openai.com/api/docs/models/gpt-6-luna) lists Responses support. On 2026-11-05, [standard pricing](https://developers.openai.com/api/docs/pricing) lists US$0.10 per million input tokens and US$0.50 per million output tokens. Confirm pricing, availability in your project, and compatibility before running; the app does not choose or fall back to a model.

For ordinary uncached text, an estimate is `inputTokens / 1,000,000 * 0.10 + outputTokens / 1,000,000 * 0.50` USD. Cache pricing and any applicable processing surcharges can change the bill. This estimate is not a spending cap. All supplied instructions, documentation, and question contribute to input usage. Output usage can include reasoning tokens, so it need not match visible answer length.

## What reaches the model

1. `CreateResponseOptions.Instructions` contains the behavioral rules: answer in the selected language (English by default), use only the supplied documentation, treat it as data, acknowledge missing information, and avoid assumptions.
2. A user input item labeled `Documentation (reference data):` contains the four fictional rules in both Portuguese and English. `--without-docs` omits this entire item and preserves the instructions.
3. A separate user input item labeled `Question:` contains your terminal input.

The [text generation guide](https://developers.openai.com/api/docs/guides/text) explains the instructions field and message roles. Labels make the data boundaries readable; they do not guarantee model compliance. No documents are retrieved and no model is trained. All input items belong to the same request, with no previous conversation.

The fictional documentation says:

- A product can only be deleted in Draft.
- Active products must be closed before archiving.
- Only ProductAdmin users can delete products.
- Restoration of deleted products is not defined.

## Application flow and limits

`Program.cs` validates arguments and environment variables, reads one question, builds the request, awaits `CreateResponseAsync`, prints the returned text and metadata, then exits. There are no application layers or extra frameworks.

- Both network timeout and cancellation deadline are 60 seconds. Stopwatch measures the API round trip, excluding typing and console output.
- Maximum output is 800 tokens, including reasoning where applicable. Incomplete responses can contain partial or empty text; the app displays their status and exits with code 1.
- The SDK normally retries HTTP 408, 429, 500, 502, 503, and 504 up to three additional times with exponential backoff. This app explicitly sets `ClientRetryPolicy(maxRetries: 0)` and adds no retry loop: at most one attempt. See [SDK retry behavior](https://github.com/openai/openai-dotnet/blob/OpenAI_2.14.0/README.md#automatically-retrying-errors).
- Missing configuration, invalid arguments, and empty input exit with code 1 before creating the client. Successful completed responses exit with code 0.
- Authentication, permission, rate/quota, connection, timeout, and other failures receive fixed English messages. Exception bodies, headers, credentials, and stack traces are not printed.
- Tokens come from API usage, not local estimates; missing usage is labeled `not reported`. Model is the identifier returned by the API.
- No history or logs are written. `StoredOutputEnabled = false` disables response storage for later retrieval; it is not a promise of zero provider retention. See [API data controls](https://developers.openai.com/api/docs/guides/your-data).
- A client timeout does not guarantee the server stopped processing or that no charges occurred. Decide manually before repeating a failed request.

## Manual experiments

Run the first command three times, entering one question per execution; use the second for experiment 4. Commands work in PowerShell and Bash:

```text
dotnet run --project ProductKnowledgeLab --no-build
dotnet run --project ProductKnowledgeLab --no-build -- --without-docs
```

| # | Question to enter | Documentation | Adequacy criterion |
|---|---|---|---|
| 1 | Quem pode excluir um produto Draft? | Yes | Identifies ProductAdmin; Draft alone is insufficient permission. |
| 2 | Um ProductAdmin pode excluir um produto Active? | Yes | Says no: only Draft can be deleted; does not confuse archiving with deletion. |
| 3 | Como restauro um produto excluído? | Yes | Explicitly says restoration is not defined; invents no procedure. |
| 4 | Como restauro um produto excluído? | No (`--without-docs`) | Says no documentation is available to support an answer. |

Record the returned model and keep it unchanged when comparing runs. Do not record secrets or sensitive questions.

| # | Returned model | Answer | Input tokens | Output tokens | Duration (s) | Adequate? / notes |
|---|---|---|---|---|---|---|
| 1 | | | | | | |
| 2 | | | | | | |
| 3 | | | | | | |
| 4 | | | | | | |

## Local validation and remaining checks

Language update validated on 2026-11-23: Debug build passed with zero warnings and errors, and all 19 offline checks passed by executing the verification script contents inline without changing execution policy. The checks cover existing validation, accepted language names/codes, option ordering, and invalid language arguments. No live model responses were tested.

Validated locally on 2026-11-05: dependency restore succeeded with authorized network access outside the sandbox; Debug build succeeded with zero warnings and zero errors. All six offline runtime checks passed: missing key/model together and individually, empty input, invalid arguments, and missing configuration with --without-docs. SDK inspection and source-level signature checks were also completed.

After a successful Debug build, run the credential-free checks:

```powershell
./Verify-Offline.ps1
```

From Bash with PowerShell 7 installed:

```bash
pwsh -File ./Verify-Offline.ps1
```

The script starts child processes with inherited key/model values removed without reading them, and uses dummy values where needed. It checks missing variables individually and together, empty input, invalid arguments, and missing configuration with --without-docs. These paths exit before any API call. Its PowerShell syntax was checked successfully. Loading the .ps1 file was blocked by the local execution policy, so the same checks were run as inline PowerShell commands and all passed. No execution policy was changed. Running the script file itself requires an environment that permits local scripts.

No paid API calls were executed. Actual model access, answers, usage, latency, and live error handling require your own experiments. Share the filled experiment table before we move to stage 2.



