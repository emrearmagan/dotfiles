# LLM Configuration

Configuration for [llm](https://github.com/simonw/llm) CLI tool.

## Setup

```bash
# Install llm
brew install llm

# Set OpenRouter API key (get from https://openrouter.ai/keys)
llm keys set openrouter

# Set default model
llm models default openrouter/openrouter/free

# Install cursor plugin
cd ~/.config/io.datasette.llm/plugins && ./install.sh
```

## Cursor Plugin

Custom plugin integrating cursor-agent with llm.

```bash
llm -m cursor/auto "your prompt"
```
