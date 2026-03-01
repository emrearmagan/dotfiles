from setuptools import setup

setup(
    name="llm-cursor",
    version="0.1.0",
    description="LLM plugin for Cursor Agent integration",
    author="Emre Armagan",
    py_modules=["llm_cursor"],
    install_requires=["llm>=0.13"],
    entry_points={"llm": ["cursor = llm_cursor"]},
)
