"""
LLM plugin for Cursor Agent integration
"""
import llm
import subprocess
import json
import os


@llm.hookimpl
def register_models(register):
    # Auto and Composer
    register(CursorAgentModel("cursor/auto", "Auto"))
    register(CursorAgentModel("cursor/composer-1.5", "Composer 1.5"))
    register(CursorAgentModel("cursor/composer-1", "Composer 1"))
    
    # GPT-5.3 Codex variants
    register(CursorAgentModel("cursor/gpt-5.3-codex-low", "GPT-5.3 Codex Low"))
    register(CursorAgentModel("cursor/gpt-5.3-codex-low-fast", "GPT-5.3 Codex Low Fast"))
    register(CursorAgentModel("cursor/gpt-5.3-codex", "GPT-5.3 Codex"))
    register(CursorAgentModel("cursor/gpt-5.3-codex-fast", "GPT-5.3 Codex Fast"))
    register(CursorAgentModel("cursor/gpt-5.3-codex-high", "GPT-5.3 Codex High"))
    register(CursorAgentModel("cursor/gpt-5.3-codex-high-fast", "GPT-5.3 Codex High Fast"))
    register(CursorAgentModel("cursor/gpt-5.3-codex-xhigh", "GPT-5.3 Codex Extra High"))
    register(CursorAgentModel("cursor/gpt-5.3-codex-xhigh-fast", "GPT-5.3 Codex Extra High Fast"))
    register(CursorAgentModel("cursor/gpt-5.3-codex-spark-preview", "GPT-5.3 Codex Spark"))
    
    # GPT-5.2 variants
    register(CursorAgentModel("cursor/gpt-5.2", "GPT-5.2"))
    register(CursorAgentModel("cursor/gpt-5.2-high", "GPT-5.2 High"))
    register(CursorAgentModel("cursor/gpt-5.2-codex-low", "GPT-5.2 Codex Low"))
    register(CursorAgentModel("cursor/gpt-5.2-codex-low-fast", "GPT-5.2 Codex Low Fast"))
    register(CursorAgentModel("cursor/gpt-5.2-codex", "GPT-5.2 Codex"))
    register(CursorAgentModel("cursor/gpt-5.2-codex-fast", "GPT-5.2 Codex Fast"))
    register(CursorAgentModel("cursor/gpt-5.2-codex-high", "GPT-5.2 Codex High"))
    register(CursorAgentModel("cursor/gpt-5.2-codex-high-fast", "GPT-5.2 Codex High Fast"))
    register(CursorAgentModel("cursor/gpt-5.2-codex-xhigh", "GPT-5.2 Codex Extra High"))
    register(CursorAgentModel("cursor/gpt-5.2-codex-xhigh-fast", "GPT-5.2 Codex Extra High Fast"))
    
    # GPT-5.1 variants
    register(CursorAgentModel("cursor/gpt-5.1-high", "GPT-5.1 High"))
    register(CursorAgentModel("cursor/gpt-5.1-codex-max", "GPT-5.1 Codex Max"))
    register(CursorAgentModel("cursor/gpt-5.1-codex-max-high", "GPT-5.1 Codex Max High"))
    register(CursorAgentModel("cursor/gpt-5.1-codex-mini", "GPT-5.1 Codex Mini"))
    
    # Claude variants
    register(CursorAgentModel("cursor/opus-4.6", "Claude 4.6 Opus"))
    register(CursorAgentModel("cursor/opus-4.6-thinking", "Claude 4.6 Opus (Thinking)"))
    register(CursorAgentModel("cursor/sonnet-4.6", "Claude 4.6 Sonnet"))
    register(CursorAgentModel("cursor/sonnet-4.6-thinking", "Claude 4.6 Sonnet (Thinking)"))
    register(CursorAgentModel("cursor/opus-4.5", "Claude 4.5 Opus"))
    register(CursorAgentModel("cursor/opus-4.5-thinking", "Claude 4.5 Opus (Thinking)"))
    register(CursorAgentModel("cursor/sonnet-4.5", "Claude 4.5 Sonnet"))
    register(CursorAgentModel("cursor/sonnet-4.5-thinking", "Claude 4.5 Sonnet (Thinking)"))
    
    # Gemini variants
    register(CursorAgentModel("cursor/gemini-3.1-pro", "Gemini 3.1 Pro"))
    register(CursorAgentModel("cursor/gemini-3-pro", "Gemini 3 Pro"))
    register(CursorAgentModel("cursor/gemini-3-flash", "Gemini 3 Flash"))
    
    # Other models
    register(CursorAgentModel("cursor/grok", "Grok"))
    register(CursorAgentModel("cursor/kimi-k2.5", "Kimi K2.5"))


class CursorAgentModel(llm.Model):
    def __init__(self, model_id, description):
        self.model_id = model_id
        self._description = description
    
    def __str__(self):
        return f"{self.model_id}: {self._description}"
    
    def execute(self, prompt, stream, response, conversation):
        # Extract model name from model_id (e.g., "cursor/auto" -> "auto")
        model_name = self.model_id.split("/", 1)[1] if "/" in self.model_id else "auto"
        
        # Get the prompt text
        prompt_text = prompt.prompt
        
        # Build cursor-agent command
        cmd = [
            "cursor-agent",
            "--print",
            "--output-format", "text",
            "--model", model_name,
            prompt_text
        ]
        
        try:
            # Run cursor-agent command
            result = subprocess.run(
                cmd,
                capture_output=True,
                text=True,
                check=True
            )
            
            # Yield the response
            yield result.stdout
            
        except subprocess.CalledProcessError as e:
            error_msg = f"Cursor agent error: {e.stderr}"
            yield error_msg
        except FileNotFoundError:
            yield "Error: cursor-agent not found. Please install it first."
