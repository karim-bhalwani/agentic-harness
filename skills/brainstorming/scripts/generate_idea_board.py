"""
generate_idea_board.py
======================
Scaffold a structured idea board from a rough concept or problem statement.
Follows the brainstorming skill's idea_board.md template format.

Generates a diverge-then-converge structure:
1. Problem reframe (3 angles on the problem)
2. Idea options (min 3, max 6, distinctly different approaches)
3. Evaluation matrix (feasibility / impact / risk per option)
4. Preferred direction (recommendation with rationale)
5. Open questions before proceeding

Usage (agent context):
    from skills.brainstorming.scripts.generate_idea_board import generate_idea_board, IdeaOption
    options = [
        IdeaOption("REST API", "Standard HTTP endpoints", feasibility=5, impact=3, risk=2),
        IdeaOption("GraphQL", "Flexible query layer", feasibility=3, impact=5, risk=3),
        IdeaOption("gRPC", "High-performance binary protocol", feasibility=2, impact=4, risk=4),
    ]
    print(generate_idea_board("Add an API layer", "Users need flexible data access", options))

Usage (CLI):
    python generate_idea_board.py --problem "Add API layer" \\
        --context "Users need flexible data access" \\
        --ideas "REST API" "GraphQL" "gRPC"
"""

from __future__ import annotations

import sys
from dataclasses import dataclass
from datetime import date
from typing import Optional


_TODO = "<!-- TODO: fill in -->"


@dataclass
class IdeaOption:
    name: str
    description: str = _TODO
    feasibility: int = 3  # 1-5 (1=very hard, 5=trivial)
    impact: int = 3  # 1-5 (1=low value, 5=high value)
    risk: int = 3  # 1-5 (1=safe, 5=very risky)
    tradeoffs: str = ""

    def score(self) -> float:
        """Simple weighted score: impact + feasibility - risk."""
        return (self.impact * 0.4) + (self.feasibility * 0.4) - (self.risk * 0.2)

    def _bar(self, value: int, length: int = 5) -> str:
        return "█" * value + "░" * (length - value)

    def matrix_row(self) -> str:
        return (
            f"| **{self.name}** "
            f"| {self._bar(self.feasibility)} {self.feasibility}/5 "
            f"| {self._bar(self.impact)} {self.impact}/5 "
            f"| {self._bar(6 - self.risk)} {self.risk}/5 "
            f"| {self.score():.1f} |"
        )


def _reframe_problem(problem: str) -> str:
    return f"""\
- **As a capability gap**: {problem} — what ability does the system currently lack?
- **As a user need**: {_TODO} — what outcome does the user actually want?
- **As a constraint removal**: {_TODO} — what current limitation would solving this remove?"""


def generate_idea_board(
    problem: str,
    context: str,
    options: list[IdeaOption],
    open_questions: Optional[list[str]] = None,
    preferred: Optional[str] = None,
) -> str:
    """
    Generate a structured idea board Markdown document.

    Parameters
    ----------
    problem : str
        The problem or opportunity to explore.
    context : str
        Background context — what the user needs, current constraints.
    options : list[IdeaOption]
        At least 3 distinctly different approaches to evaluate.
    open_questions : list[str], optional
        Questions that must be answered before committing to a direction.
    preferred : str, optional
        Name of the recommended option. Auto-selects highest scorer if omitted.

    Returns
    -------
    str
        Markdown idea board ready to save as idea_board.md.
    """
    if len(options) < 3:
        raise ValueError("An idea board requires at least 3 options for meaningful comparison.")

    sorted_options = sorted(options, key=lambda o: o.score(), reverse=True)
    recommended = preferred or sorted_options[0].name

    sections: list[str] = []

    sections.append(f"# Idea Board: {problem}\n")
    sections.append(f"> {date.today()} | Status: DIVERGING — not committed to any direction\n")
    sections.append("---\n")

    sections.append("## Context\n")
    sections.append(f"{context}\n")

    sections.append("## Problem Reframe\n")
    sections.append("_Exploring the problem from 3 angles before jumping to solutions:_\n")
    sections.append(_reframe_problem(problem))
    sections.append("")

    sections.append("## Options\n")
    for i, opt in enumerate(options, 1):
        sections.append(f"### Option {i}: {opt.name}\n")
        sections.append(f"{opt.description}\n")
        if opt.tradeoffs:
            sections.append(f"**Tradeoffs**: {opt.tradeoffs}\n")

    sections.append("## Evaluation Matrix\n")
    sections.append("| Option | Feasibility | Impact | Safety | Score |")
    sections.append("|--------|-------------|--------|--------|-------|")
    for opt in sorted_options:
        sections.append(opt.matrix_row())
    sections.append("\n_Feasibility: 5=easy. Impact: 5=high value. Safety: 5=low risk. Score = weighted composite._\n")

    sections.append("## Preferred Direction\n")
    sections.append(f"**Recommendation**: {recommended}\n")
    sections.append(f"**Rationale**: {_TODO}\n")
    sections.append(
        "_This is a directional preference, not a commitment. "
        "Hand off to `architect` to validate technical feasibility and produce a spec._\n"
    )

    sections.append("## Open Questions\n")
    sections.append("_These must be answered before handing off to `architect`:_\n")
    if open_questions:
        for i, q in enumerate(open_questions, 1):
            sections.append(f"{i}. {q}")
    else:
        sections.append(f"1. {_TODO}")
        sections.append(f"2. {_TODO}")
    sections.append("")

    sections.append("---")
    sections.append(
        "_Generated by `brainstorming/scripts/generate_idea_board.py`. "
        "Fill all `<!-- TODO -->` markers, then hand off to `architect` for specification._"
    )

    return "\n".join(sections)


def main() -> None:
    import argparse

    parser = argparse.ArgumentParser(description="Generate a structured idea board")
    parser.add_argument("--problem", required=True, help="Problem or opportunity to explore")
    parser.add_argument("--context", default=_TODO, help="Background context")
    parser.add_argument("--ideas", nargs="+", required=True, help="2-6 option names to evaluate")
    parser.add_argument("--questions", nargs="*", default=None, help="Open questions before committing")
    parser.add_argument("--output", default=None, help="Write to file (default: stdout)")
    args = parser.parse_args()

    if len(args.ideas) < 3:
        print("❌ Provide at least 3 ideas for comparison.", file=sys.stderr)
        sys.exit(1)

    options = [IdeaOption(name=name) for name in args.ideas]
    output = generate_idea_board(
        problem=args.problem,
        context=args.context,
        options=options,
        open_questions=args.questions,
    )

    if args.output:
        from pathlib import Path

        Path(args.output).write_text(output, encoding="utf-8")
        print(f"✅ Idea board written to {args.output}")
    else:
        print(output)


if __name__ == "__main__":
    main()
