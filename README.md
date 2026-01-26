Claude Code in a Container
==========================

This project allows you to run Claude Code, configured to use models via
Vertex, inside a Podman container with SELinux isolation. This means that only
the files on your current project are available to Claude; it has no ability to
either see other files or modify your system.

In addition, Claude is configured to use its own sandbox, which blocks the Bash
tool from writing to files outside of your project, in exchange for not
prompting you to approve each command. (Note that in my experience you must
also be in "accept edits" mode to skip the prompts. Press Shift-Tab to cycle
between modes.) It also has a network proxy that allows it to control any
network access by the Bash tool.

Why Run Claude Code in a Container?
-----------------------------------

Many commentators have observed that running Claude Code with
[`--dangerously-skip-permissions`](https://dangerously-skip-permissions.com/)
is a [qualitatively different
experience](https://simonwillison.net/2025/Oct/22/living-dangerously-with-claude/)
to running without. When you don't have to constantly approve each command to
make progress, you can set Claude to work on a problem and go do something
else. (Often the task could be something like fixing a broken unit test, which
requires many experiments but not necessarily large-scale code changes.)

Unfortunately, as the name suggests, this is dangerous. There are many ways to
give the LLM access to untrusted input (e.g. random review comments on a public
repository), and it will be only too happy to follow any instructions therein.
Meanwhile, it has the ability to write arbitary code and run it, with full
access to the environment in which it is running. And, in fact, this is largely
true even when you don't skip permissions: if you have given Claude permission
to run your tests, and it is also in a mode where it can write code, then it
can run arbitrary code in your environment, possibly at the instruction of an
untrusted attacker.

Claude Code now has [its own sandbox
mode](https://www.anthropic.com/engineering/claude-code-sandboxing), but
unfortunately it is not very helpful for this problem. It is focused on
preventing network egress to avoid exfiltration of data, and as such it only
prevents _modifying_ files outside of the project (to avoid circumventing the
network proxy), not reading them. Thus it can prevent the LLM [running `rm -rf
~`](https://github.com/anthropics/claude-code/issues/10077), but not reading
your SSH private key and posting it on some site that you have previously given
permission for (e.g. GitHub). Furthermore, if any command fails as a result of
the sandboxing, the LLM can **and will** simply retry it outside of the
sandbox.

Running inside a container means that Claude Code can only see and modify data
that is explicitly mounted into the container environment. Using Podman means
the container can be run without root permissions, reducing the danger of
privilege escalation, and using SELinux means that the isolation is enforced by
mandatory access control. Within the container, you can allow Claude to install new packages without affecting your system.

If your personal risk calculus allows it, you may choose to run with
`--dangerously-skip-permissions` inside the container. However, the sandbox
mode is also enabled and this has the effect of reducing the permission
requests that you generally would not want to see (allowing Claude to grind
away in the background with sandboxed commands in accept-edits mode) without
eliminating all permissions checks.

Installation
------------

First, you must log in to GCloud to provide access to Vertex by doing:

```
gcloud auth application-default login
gcloud auth application-default set-quota-project ...
```

Running the following script will build the container on linux or Mac OS:

```
path/to/claude-container/build-claude.sh
```

The easiest way to run Claude is to add an alias in your `~/.bashrc` (or `~/.profile` on Mac OS) file:

```
alias claude="path/to/claude-container/claude"
alias yolo="path/to/claude-container/claude --dangerously-skip-permissions"
```

Then just run `claude` in your project directory (from a new shell). The first
time will take a while as it builds the container image locally.

Updating
--------

Auto-updating is disabled. To update, rebuild the container image by running
`build-claude.sh --rebuild`. This restarts the image build with the latest
version of Fedora and its packages as well as Claude Code.

GitHub integration
------------------

To allow Claude to use the `gh` CLI command, [create a fine-grained personal access token](https://docs.github.com/en/enterprise-cloud@latest/authentication/keeping-your-account-and-data-secure/managing-your-personal-access-tokens#creating-a-fine-grained-personal-access-token) and store it in the Podman Secret `claude-github-token` by copying it to the clipboard and doing:

```
podman secret create --replace claude-github-token <(wl-paste)
```

Example permissions:

* [Read public repos only](https://github.com/settings/personal-access-tokens/new?name=claude+container&description=Read-only+token+for+public+repos&expires_in=none)
* [Read public and private repos (including Issues and PRs)](https://github.com/settings/personal-access-tokens/new?name=claude-container&description=Read-only+token+for+public+and+private+repos&contents=read&pull_requests=read&issues=read)
* [Write to repos, PRs, and Issues](https://github.com/settings/personal-access-tokens/new?name=claude-container&description=Read+and+Write+to+repos,+PRs,+and+Issues&contents=write&pull_requests=write&issues=write)

To pass through **all** of your GitHub permissions (not recommended!), you can
do:

```
gh auth token | podman secret create --replace claude-github-token
```

Drawbacks
---------

It is currently not possible to run a nested Podman container inside the
container. Unfortunately getting this working would require [disabling SELinux
labelling](https://www.redhat.com/en/blog/podman-inside-container) on the outer
container.

Other capabilities may be disabled or packages missing simply because I haven't
encountered a need for them yet. Pull requests are welcome.
