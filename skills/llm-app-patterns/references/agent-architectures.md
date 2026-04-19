# Agent Architectures

Comprehensive guide to different agent patterns and when to use them.

## When to Use This Reference

Use when:

- Building agents that need to use tools or take actions
- Implementing multi-step reasoning workflows
- Creating collaborative multi-agent systems
- Choosing between agent architectures

---

## ReAct Pattern (Reasoning + Acting)

Pattern: Thought → Action → Observation loop

```python
REACT_PROMPT = """
You are an AI assistant that can use tools to answer questions.

Available tools:
{tools_description}

Use this format:
Thought: [your reasoning about what to do next]
Action: [tool_name(arguments)]
Observation: [tool result - this will be filled in]
... (repeat Thought/Action/Observation as needed)
Thought: I have enough information to answer
Final Answer: [your final response]

Question: {question}
"""

class ReActAgent:
    def __init__(self, tools: list, llm):
        self.tools = {t.name: t for t in tools}
        self.llm = llm
        self.max_iterations = 10

    def run(self, question: str) -> str:
        prompt = REACT_PROMPT.format(
            tools_description=self._format_tools(),
            question=question
        )

        for _ in range(self.max_iterations):
            response = self.llm.generate(prompt)

            if "Final Answer:" in response:
                return self._extract_final_answer(response)

            action = self._parse_action(response)
            observation = self._execute_tool(action)
            prompt += f"\nObservation: {observation}\n"

        return "Max iterations reached"
```

## Function Calling Pattern

Native function calling support for tool use:

```python
TOOLS = [
    {
        "name": "search_web",
        "description": "Search the web for current information",
        "parameters": {
            "type": "object",
            "properties": {
                "query": {"type": "string", "description": "Search query"}
            },
            "required": ["query"]
        }
    },
    {
        "name": "calculate",
        "description": "Perform mathematical calculations",
        "parameters": {
            "type": "object",
            "properties": {
                "expression": {"type": "string", "description": "Math expression"}
            },
            "required": ["expression"]
        }
    }
]

class FunctionCallingAgent:
    def run(self, question: str) -> str:
        messages = [{"role": "user", "content": question}]

        while True:
            response = self.llm.chat(messages=messages, tools=TOOLS, tool_choice="auto")

            if response.tool_calls:
                for tool_call in response.tool_calls:
                    result = self._execute_tool(tool_call.name, tool_call.arguments)
                    messages.append({
                        "role": "tool",
                        "tool_call_id": tool_call.id,
                        "content": str(result)
                    })
            else:
                return response.content
```

## Plan-and-Execute Pattern

Break complex tasks into plans, then execute:

```python
class PlanAndExecuteAgent:
    """
    1. Create a plan (list of steps)
    2. Execute each step
    3. Replan if needed
    """

    def run(self, task: str) -> str:
        # Planning phase
        plan = self.planner.create_plan(task)

        results = []
        for step in plan:
            result = self.executor.execute(step, context=results)
            results.append(result)

            # Check if replan needed
            if self._needs_replan(task, results):
                new_plan = self.planner.replan(
                    task,
                    completed=results,
                    remaining=plan[len(results):]
                )
                plan = new_plan

        return self.synthesizer.summarize(task, results)
```

## Multi-Agent Collaboration

Specialized agents working together:

```python
class AgentTeam:
    def __init__(self):
        self.agents = {
            "researcher": ResearchAgent(),
            "analyst": AnalystAgent(),
            "writer": WriterAgent(),
            "critic": CriticAgent()
        }
        self.coordinator = CoordinatorAgent()

    def solve(self, task: str) -> str:
        assignments = self.coordinator.decompose(task)

        results = {}
        for assignment in assignments:
            agent = self.agents[assignment.agent]
            result = agent.execute(assignment.subtask, context=results)
            results[assignment.id] = result

        critique = self.agents["critic"].review(results)

        if critique.needs_revision:
            return self.solve_with_feedback(task, results, critique)

        return self.coordinator.synthesize(results)
```

## Architecture Decision Matrix

| Pattern              | Use When         | Complexity | Cost      |
| :------------------- | :--------------- | :--------- | :-------- |
| **ReAct Agent**      | Multi-step tasks | Medium     | Medium    |
| **Function Calling** | Structured tools | Low        | Low       |
| **Plan-Execute**     | Complex tasks    | High       | High      |
| **Multi-Agent**      | Research tasks   | Very High  | Very High |

## Best Practices

- **ReAct**: Best for general multi-step reasoning with tools
- **Function Calling**: Use when you have well-defined tool schemas
- **Plan-Execute**: For complex tasks requiring explicit planning
- **Multi-Agent**: For tasks benefiting from specialized expertise
- **Iterations**: Limit max iterations (10-15) to prevent infinite loops
- **Tool Selection**: Provide clear, specific tool descriptions


