Understood. I’ll perform deep research into best practices and community examples (since May 16, 2025) for AGENTS.md files used with the cloud-hosted OpenAI Codex platform, especially for general-purpose software development (vibe coding).

I’ll synthesize findings from official OpenAI documentation and recent community usage patterns to deliver a definitive and comprehensive guide. I’ll notify you once it’s ready.


# AGENTS.md in OpenAI Codex: Best Practices and Effective Use

## Overview of OpenAI Codex and AGENTS.md Files

OpenAI **Codex** is a cloud-based AI software engineering agent integrated into ChatGPT for Pro, Team, and Enterprise users. It can handle tasks like writing code, answering questions about a codebase, fixing bugs, and proposing pull requests in parallel, all within isolated cloud containers preloaded with your repository. To guide these **Codex agents** on project-specific needs, OpenAI introduced the **`AGENTS.md`** file. This file acts like a *README for robots*, providing instructions so the AI works with your codebase in the desired way. In short, `AGENTS.md` is a plain-text Markdown file (similar to a README) placed in your repo or environment, where you inform Codex how to navigate the code, run tests, follow coding conventions, and adhere to project standards.

Including an `AGENTS.md` is optional, but it can significantly improve Codex’s effectiveness by aligning it with your team's workflows and coding style. Like human developers, Codex performs best with a clear spec of the development environment, reliable test instructions, and coding guidelines. This guide compiles official documentation and recent community insights (as of May 2025) on how to structure and use `AGENTS.md` files for general-purpose *“vibe coding”* workflows – an AI-assisted approach where you describe intentions and let the agent handle implementation. We’ll cover the official specification, hierarchical configuration (global vs. local scopes), recommended content and syntax, real-world examples, and common pitfalls (with solutions) to help you create an effective `AGENTS.md` for your Codex agents.

## Official Specification and Agent Behavior

**OpenAI’s guidelines** outline how Codex detects and uses `AGENTS.md` files during its operations. Key points from the official spec include:

* **Placement and Discovery:** Codex will look for `AGENTS.md` files anywhere in the container’s filesystem (typical locations include the repo root, subfolders, or even the user’s home directory). In the open-source Codex CLI, for example, the agent merges instructions from up to three locations: a personal global file (e.g. `~/.codex/AGENTS.md`), an `AGENTS.md` at the repository root, and one in the current working directory (for feature- or folder-specific rules). This allows layered configurations for global, project, and local scopes.

* **Scope of Instructions:** Each `AGENTS.md` file applies to the directory **tree rooted at the folder containing that file**. The agent is trained to **search for any `AGENTS.md` whose scope includes a file it is about to modify**, and then obey the instructions relevant to that scope. For example, if a task involves editing files under `src/`, Codex will apply rules from an `AGENTS.md` in `src/` (if present) in addition to any relevant rules from the root or global file.

* **Hierarchical Precedence:** If multiple `AGENTS.md` files apply (e.g. one at root and another in a subfolder), **the deeper (more specific) file takes precedence** in case of conflicting instructions. In other words, local folder-specific guidance can override more general project-wide guidance. All applicable instructions are merged in a cascading way (global → project → subdirectory), with later overrides where needed. This hierarchy lets you provide broad default rules and then refine or override them in specific parts of a codebase.

* **Instruction Types:** `AGENTS.md` can include many kinds of guidance. Common examples are:

  * **Project layout and code navigation:** e.g. descriptions of key directories or modules so the agent understands where things are organized.
  * **Build and test commands:** e.g. how to run the test suite, linters, or compile steps. If the file lists programmatic checks (like test commands or build steps), Codex **must run all of them after making changes** to verify its work. For instance, you might instruct *“Run `pytest tests/` before finalizing a PR”* or provide a shell snippet for running a gradle build.
  * **Coding style and conventions:** e.g. which formatter or style guide to use, naming conventions, or language-specific practices. You can specify things like *“Use Black for Python formatting”* or *“Avoid abbreviations in variable names”*. The model has been trained to respect such code style instructions within their scope.
  * **Commit message and PR guidelines:** e.g. templates or standards for commit messages and pull request descriptions. You can instruct how to format PR titles, require certain sections (like a “Testing Done” section), or follow a specific commit style guide. Codex will use these instructions when composing its commit or PR messages.
  * **Additional rules or tips:** virtually any other directives that a developer might give a new team member. This could include things like *“Don’t modify certain files,”* *“Prefer functional components over class components (in React),”* or even playful touches like asking the agent to output an ASCII art cat between steps (yes, you can do that – the agent will attempt to follow any clear instruction!).

* **Obedience and Overrides:** The agent is expected to **adhere to all instructions** in relevant `AGENTS.md` files for any code it touches. However, if a user’s direct instruction (via prompt) conflicts with something in `AGENTS.md`, the **user prompt takes precedence**. In practice, this means you can always override the automatic guidelines if needed (for example, telling the agent “skip running tests this time” would trump an Agents.md rule about running tests). Absent an override, the agent will diligently follow the rules you’ve set.

* **Agent Training and Performance:** OpenAI fine-tuned the Codex model (`codex-1`) to **explicitly respect Agents.md instructions** in the above categories (testing, style, location of code, commit messaging, etc.). Internal benchmarks showed that providing an `AGENTS.md` can boost the agent’s effectiveness; codex-1 achieved higher accuracy on coding tasks when guided by an `AGENTS.md` versus unguided or older models. That said, Codex is still reasonably strong even without a guide, so *not* having an `AGENTS.md` won’t break it – but having one serves as a helpful “blueprint” or configuration to get more reliable, on-style results.

## Structuring an Effective AGENTS.md

An `AGENTS.md` file should be **clear, organized, and tailored** to your project. Think of it as writing instructions for a junior developer or an intern (except the intern is an AI) on how to work with your code. Here are best practices for structure and syntax, backed by effective patterns observed in community examples:

* **Use Markdown Headings and Sections:** Organize the file by topics (just as you would a README). Common section headings include **Code Style**, **Testing**, **Build/Run Instructions**, **Commit Messages/PR Guidelines**, **Project Structure**, etc. This helps the agent parse the document logically. For example, a simple Agents.md might start like this:

  ```markdown
  # AGENTS.md

  ## Code Style
  - Use Black for Python formatting.
  - Avoid abbreviations in variable names.

  ## Testing
  - Run pytest tests/ before finalizing a PR.
  - All commits must pass lint checks via flake8.

  ## PR Instructions
  - Title format: [Fix] Short description
  - Include a one-line summary and a "Testing Done" section.
  ```

  *Example*: The above snippet shows a concise `AGENTS.md` defining Python style conventions, test commands, and PR format rules. By clearly sectioning these instructions, Codex can easily find and apply the relevant rules when writing code, running tests, or composing commit messages.

* **Prefer Bullet Points or Numbered Lists for Rules:** Each guideline should be in a bullet or step list, phrased as a directive. This makes it straightforward for the model to identify distinct instructions. For instance, using a numbered list for build steps under a **Build** section (Step 1: install dependencies, Step 2: run tests, etc.) helps the agent know the exact sequence of actions to perform. Bulleted lists for style rules or dos/don’ts (as shown above) clearly delineate each requirement. Avoid burying critical instructions in long paragraphs – succinct bullet points are more likely to be noticed and followed.

* **Include Code Fences for Commands or Code Snippets:** When telling the agent how to execute something (like running a tool or a test), it's helpful to put the exact command in a fenced code block. For example:

  ````markdown
  ## Building and Testing
  1. Format the code before committing: 
     ```bash
     ./gradlew --offline spotlessApply
  ````

  2. Run the test suite:

     ```bash
     ./gradlew test
     ```

  ```
  This format (taken from a real `AGENTS.md` in an open-source project) explicitly shows the shell commands to run:contentReference[oaicite:33]{index=33}. Codex will pick up those commands and attempt to run them as part of its workflow. By providing exact commands or script invocations, you remove guesswork – the agent doesn’t have to infer how to run tests or builds, it can follow your recipe. Ensure any such commands are up-to-date and working in the repository’s environment.

  ```

* **Be Specific and Unambiguous:** Write instructions that are easy to interpret. Instead of saying "ensure tests pass", say *which* tests and how to run them (as above). Instead of "follow our coding style", reference the specific linter/formatter or style guide. For commit messages, if you have a format, demonstrate it. E.g., *“Follow the [Chris Beams](http://chris.beams.io/posts/git-commit/) style for commit messages”* or *“Answer ‘What changed? Why? Any breaking changes?’ in every PR description”*. The model will mirror these guidelines in its output – for instance, formatting its commit message accordingly or writing code in the style you prefer.

* **Keep it Concise and Relevant:** While you want to be thorough, avoid turning the Agents.md into an overwhelming essay. The AI will read this file frequently, so **signal-to-noise ratio matters**. Community experts suggest keeping the file "short and relevant" – include all key rules, but skip extraneous commentary. If a rule only applies to a very specific scenario, consider whether it belongs in a global Agents.md or perhaps as a comment in code or a more localized Agents.md. Aim for a document that a new contributor could quickly scan to understand how to contribute; the agent will similarly benefit from brevity and clarity.

* **Use Hierarchy for Different Contexts:** If your project spans multiple languages or modules with distinct workflows, leverage multiple `AGENTS.md` files. For example, at the root you might have general guidelines (coding style, PR rules, high-level build/test instructions), and in a subdirectory (say, `frontend/` vs `backend/`) you might have an `AGENTS.md` with specifics for that part (like front-end linting rules or backend testing steps). Codex will apply the appropriate ones automatically based on which files it's working on. This way, you keep each file focused and relevant to its scope. Remember that deeper `AGENTS.md` override higher-level ones on conflicts, so you can fine-tune behavior in specialized areas without duplicating all instructions.

* **Maintain it Like Documentation:** Treat `AGENTS.md` as a living document. As your project evolves (new test commands, new style conventions, changes in how you structure code), update the file. The agent isn’t magic – it only knows what you tell it in the repository. Many teams integrate such guides into their repository’s version control, similar to a CONTRIBUTING guide. Also, because Codex is a research preview, its capabilities will improve over time; you might be able to add more nuanced instructions as the model becomes smarter. Keeping `AGENTS.md` up to date ensures you continue getting the best results.

## Best Practices from the Community

Early adopters and experts have shared tips on making the most of Codex with `AGENTS.md`. Here are some **community-driven best practices** and insights, especially from recent discussions (mid-2025):

* **Seed it with the Basics, Then Iterate:** You don’t need a perfect `AGENTS.md` from the start. Include the core pieces (project structure, how to test, style guidelines, etc.), then let the agent work. **Watch the agent’s worklog** (the terminal logs and actions Codex produces) to spot where it struggles. If you notice it making mistakes or needing hints (e.g. it didn’t run a needed build step, or got a style wrong), update `AGENTS.md` with that guidance. Over time you can refine the file to cover more edge cases. The Codex team notes that this iterative approach is effective – you *“learn over time”* what to put in Agents.md as you see the agent in action.

* **Leverage Codex to Write Agents.md:** In a recursive twist, you can ask Codex itself to draft or improve your `AGENTS.md`. For example, if you already have a CONTRIBUTING.md or a well-structured project, you can use an “Ask” prompt like *“Create an AGENTS.md for this repository”*. Users have reported success having Codex generate an initial draft by summarizing existing documentation. In fact, the OpenAI Codex team revealed they sometimes *“have O3 (another model) and GPT-4 write our Agents.md files for us”*, as a starting point. Of course, you should review and edit any AI-generated instructions for accuracy before trusting them. But this technique can jump-start the process or help integrate changes faster.

* **Embrace Hierarchical Configuration:** As mentioned, the hierarchical nature of `AGENTS.md` is by design. Community members refer to it as *“the new hierarchical Agents.md designed to capture all your instructions”*. To use this effectively, keep global guidelines in a global file (or home directory for CLI) for preferences that apply to all projects, use project-level files for team/project standards, and sub-folder files for context-specific tweaks. One power user tip is to maintain a **personal `~/.codex/AGENTS.md`** with your own preferences (if using the CLI) – for example, always prefer certain libraries, or personal style choices – so those apply everywhere by default. Then rely on project `AGENTS.md` to override those where needed. This scoping avoids repeating yourself and keeps each config focused.

* **“Groom” Your Agents.md as an AI Playbook:** Think of Agents.md as a playbook that grows alongside the AI’s capabilities. A tip from OpenAI’s Codex team is to proactively *groom* this file – don’t set it and forget it. Add new rules when you notice a gap, and remove or adjust instructions that are no longer helpful. The idea is to capture institutional knowledge that you want the AI to have. As Codex's model improves, you can incorporate more abstract guidelines (for example, if future versions handle design patterns, you might add “prefer composition over inheritance in new code”). Right now, focus on concrete, actionable instructions the current model can reliably follow (tests, formatting, naming, etc.). Over time, your `AGENTS.md` can evolve from simple checks to a comprehensive coding guide for the AI.

* **Parallelize and Compare Approaches:** A novel “vibe coding” tip enabled by Codex is to run multiple agent tasks in parallel – even having them tackle the same problem in different ways – and then compare results. This isn’t a direct feature of `AGENTS.md`, but you can use it in the process of refining the file. For example, you could prompt two Codex instances to *“draft an Agents.md for this repo”* and perhaps another to *“list any missing instructions in this Agents.md”*, then merge the best insights. This leverages Codex’s parallel task capability to ensure your guide is robust. In practice, multiple parallel tasks are more commonly used for coding solutions, but the concept of using them for meta-tasks like configuring the agent is emerging in the community.

* **Use Agents.md for Onboarding New Contributors (Human or AI):** Some teams treat `AGENTS.md` as a unified documentation that benefits both AI agents and new human contributors. It overlaps with CONTRIBUTING.md but is aimed at what an AI needs. Interestingly, because it’s plain text, a human can read it too and quickly glean the “rules of the repo.” This dual utility means writing a good Agents.md can improve the consistency of all contributions. As one Medium article put it, *the Agents.md functions as a blueprint or guidebook for how the AI should operate, ensuring alignment with team standards*. In vibe coding workflows, where a developer is overseeing many AI-driven tasks, having this central reference keeps the AI’s output predictable and on-spec, which in turn makes it easier for the human to trust and integrate the changes.

* **Stay Agnostic to Language/Stack in Wording:** Codex works across many languages and frameworks, so phrase your instructions in a way that’s unambiguous in context. If your repo has multiple languages, it's fine to have a section per language or module. Codex will only apply what's relevant (since it looks at scope and possibly also discerns which instructions apply based on file context). For example, you might have **“Use Prettier for JavaScript formatting”** in a web app folder’s Agents.md, and **“Use Black for Python formatting”** in the backend folder. Each agent working in those areas will follow the appropriate rule. Keep terminology consistent with what tools and frameworks expect (e.g. use exact tool names and commands). The goal is to ensure Codex never has to guess your intent.

## Real-World Examples of AGENTS.md

To illustrate, here are snapshots of how organizations and developers are using `AGENTS.md` files effectively:

* **Basic Template (General-Purpose):** A minimal but effective template might include:

  * **Code Style:** e.g. "*Follow PEP8 style. 80 character line limit.*"
  * **Testing:** e.g. "*Run `npm test` after changes; ensure all tests pass.*"
  * **Documentation:** e.g. "*Update README.md if public APIs change.*"
  * **Commit Message:** e.g. "*Use present-tense, imperative mood in commit messages.*"

  This template ensures the agent formats code and verifies it meets basic quality gates. In a DataCamp tutorial, such a file was shown guiding Codex to automatically format with Black, run pytest and flake8, and produce well-formed PR descriptions. Even this short list can prevent common issues (like style nits or failing CI tests) by catching them before the agent finalizes its work.

* **Comprehensive Project Guide (Example: Temporal’s SDK)**: The Temporal open-source team prepared a detailed `AGENTS.md` for their Java SDK repository. It includes:

  * A **Repository Layout** section listing each module and its purpose (to orient the AI in the code structure).
  * **General Guidance:** rules like avoiding changes to public APIs and noting the Java version target.
  * **Building and Testing:** step-by-step commands to format code (using Gradle’s spotless plugin), run the full test suite (with notes about needing a local server), and even how to run subsets of tests with Gradle filters. This ensures Codex knows exactly how to compile and test this project.
  * **Tests:** clarifications on where tests live and how they should be written (e.g. using JUnit4, certain test utilities).
  * **Commit Messages and PRs:** a reference to a well-known commit style guide and a checklist of questions every pull request description should answer (what changed, why, any breaking changes, etc.). The agent, following this, will format its commit and PR text to match Temporal’s conventions.
  * A **Review Checklist:** listing conditions for code review such as all tests passing, new tests added for new features, docs updated, etc.. Codex will attempt to satisfy these before considering its task done (for example, it will run `./gradlew spotlessCheck` and ensure tests pass, per these instructions).

  This real example shows how `AGENTS.md` can encapsulate a project's contribution guide in a single file for the AI. The result is the Codex agent acting almost like a trained new developer: it formats code correctly, runs all required checks, writes commit messages in the expected style, and doesn't, say, forget to update docs. Temporal’s team noted that they could even **ask Codex to help generate parts of this file** by pointing it at existing docs.

* **Community Projects and Templates:** Beyond official examples, independent developers have started sharing their `AGENTS.md` templates. For instance, one blog post described listing a project's logging approach, preferred design patterns, and testing libraries in the Agents.md so that Codex would use the correct logger and patterns consistently. Another user on X (Twitter) emphasized that `AGENTS.md` is just a Markdown file the agent reads to understand the repo, and highlighted that it can be **nested per folder with overrides**. There are also emerging tools and prompts collections (e.g. *vibecodex.io* and others) that include suggestions for what to put in an Agents.md for different tech stacks (like web development vs. data science). While these are not official, they indicate a growing community practice of tailoring Agents.md content to the type of project.

In summary, real-world usage ranges from lightweight files with a few key rules to very detailed guides covering multiple aspects of development. The most effective ones share a common theme: **they anticipate what the AI needs to know to work autonomously on the codebase.** By reviewing your own development practices (what steps you always run, what mistakes you avoid, how you structure commits), you can encode that knowledge into the `AGENTS.md`. Successful examples show that when done well, the AI agent’s contributions fit neatly into the project’s workflow (passing tests, conforming to style, etc.) with minimal corrections.

## Common Pitfalls and How to Avoid Them

Despite the power of `AGENTS.md`, users have encountered some misunderstandings or issues. Learn from these common pitfalls:

* **Not Using an Agents.md at All:** The simplest pitfall is neglecting this file. Codex will still try its best without one, but you miss out on guiding it. Solution: *create at least a basic `AGENTS.md`.* Even a few lines about tests and style can make a difference. As one source quipped, *having some Agents.md will get you a long way rather than none*. If you don’t know where to start, have Codex draft one or use a template.

* **Vague or Implicit Instructions:** If the `AGENTS.md` says *“ensure code is well-documented”* or *“maintain best practices”* without specifics, the agent might ignore or misinterpret it. The model works best with concrete directives it can act on. Solution: *be explicit.* For documentation, say “Add or update docstrings for any function you modify.” For best practices, specify them (e.g. “Use `async/await` for asynchronous code, do not use raw threads.”). Don’t assume the AI knows your intent – spell it out in actionable terms.

* **Overly Verbose Files:** On the flip side, a massive `AGENTS.md` with hundreds of lines of every minor rule can dilute important points. Remember, *“the richer the instructions, the smoother Codex behaves”* – “richer” meaning high-value content, not sheer volume. If you include irrelevant or outdated info, the agent might become confused or waste time. Solution: *keep the file focused on what truly matters for successful contributions*. You can remove sections that aren’t impacting the agent’s behavior or that cover edge cases better handled through direct prompts when needed. Use comments or separate documentation for human-only guidance, and keep Agents.md laser-focused on what the agent should do every time.

* **Incorrect File Placement or Naming:** A simple gotcha is placing the file in the wrong location or misnaming it. It **must be named exactly `AGENTS.md`** (all caps) for Codex to recognize it. Also, ensure it’s included in the repo or container. If you draft one but never commit it, the cloud Codex (which pulls your repo from GitHub) won’t see it. If using the CLI, remember the merge order – your project’s file might be overridden by a lingering global file if you forgot about it. Solution: *Double-check the file name and hierarchy.* Put the project’s Agents.md at the root of the repository for general rules, and any additional ones in the appropriate sub-folders. If Codex seems to ignore your instructions, verify it’s reading the right file (the worklog often indicates which Agents.md were loaded). For CLI, use the `--no-project-doc` flag to troubleshoot if perhaps an unintended global config is interfering.

* **Conflicting Instructions:** If you maintain multiple Agents.md files, there’s a risk of conflicts (e.g., root file says “use 4 spaces indent” and a subfolder file says “use 2 spaces” for a different language). Fortunately, Codex has a defined rule: deeper scopes override higher ones. However, conflicts can still confuse if not planned (the agent might flip context if working across folders). Solution: *avoid unnecessary contradictions.* Only override when genuinely needed. In the above example, it’s better to scope style rules by language or folder so they don’t actually conflict on the same file. If a conflict is unavoidable, trust the precedence rules, but consider adding a comment in the Agents.md to clarify (for human maintainers) why it’s different in that sub-scope.

* **Expecting Dynamic Decision-Making from Agents.md:** Some users initially expected Codex to *decide* what tasks to do from Agents.md (i.e. as if it were an autonomous agent planning new work because of the file). In reality, Agents.md is more of a configuration reference, not a to-do list. Codex will not start doing things on its own just because an Agents.md suggests “areas to improve” or similar. It waits for your prompt/task. Solution: *use Agents.md for guidelines, not task instructions.* For example, do put “Run tests X, Y after changes,” but don’t put “Implement feature Z” in the file and expect Codex to do it automatically. If you want Codex to generate tasks for itself, you can explicitly ask it (there’s an “Ask Codex what to do next” approach in vibe coding), but that’s separate from Agents.md’s role.

* **Neglecting to Update Agents.md:** A stale Agents.md can be misleading. If your project switches to a new test framework but the file still references the old one, Codex might run the wrong tests or waste time. Similarly, if team practices change (say, you adopt Conventional Commits for messages), update the file accordingly. Solution: *treat Agents.md as code.* When something changes in your dev process, modify Agents.md in the same commit or sprint. Encourage contributors to propose changes to Agents.md if they find Codex needed a new hint. In fact, as the Codex team hinted, they envision possibly auto-generating or updating Agents.md in the future based on agent performance and user feedback. For now, it’s on you to maintain it.

By being aware of these pitfalls, you can avoid frustration and ensure your Agents.md truly benefits your AI coding partner. In cases where Codex does something unexpected, check whether the guidance file covered that scenario – it might just be a missing instruction that you can add for next time.

## Conclusion

**AGENTS.md files have quickly become a cornerstone of effective “vibe coding” with OpenAI Codex.** They transform a code repository into a friendly environment for an AI collaborator by codifying the project's norms and procedures. Officially, they function as a bridge between human intent and AI action – instructing Codex *how* to work rather than *what* to work on. By following the best practices outlined above – clear structure, explicit directives, proper scoping, and iterative refinement – you can create an Agents.md that turns Codex into a reliable pair programmer aligned with your project’s needs.

The early community experiences in 2025 show that when used well, `AGENTS.md` can elevate Codex from a code generator to a true software **agent**: running the right tests automatically, formatting code to your liking, writing commits that could pass a code review, and generally embedding your team's “institutional knowledge” into every AI-driven task. As vibe coding becomes more prevalent, think of your Agents.md as the playbook that ensures the AI develops *your* project’s vibe, not its own. With careful guidance and ongoing tuning, Codex can significantly accelerate development cycles while adhering to the standards you set – a win-win for productivity and code quality.

In practice, adopting Agents.md is straightforward: start small, observe Codex’s behavior, and keep enriching the file. Soon, you’ll have a general-purpose AI agent that feels like part of the team, seamlessly coding in tandem with human developers. Happy vibe coding, and don’t forget to keep that Agents.md handy as your project’s AI compass!

**Sources:** The information and recommendations above draw from OpenAI’s official Codex announcement and documentation, insights shared by the Codex development team (e.g. Reddit AMA, latent.space podcast), and community experiences from blogs and guides (DataCamp, Temporal.io, Medium, etc.). These sources are cited throughout for reference to specific details.
