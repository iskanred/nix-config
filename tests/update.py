#!/usr/bin/env python3
"""Exercise generated update runners and dr dispatch without network or activation."""

import json
import os
from pathlib import Path
import subprocess
import tempfile


SOURCE = Path(__file__).resolve().parents[1]


def execute(arguments, **kwargs):
    return subprocess.run(arguments, text=True, capture_output=True, **kwargs)


with tempfile.TemporaryDirectory(prefix="nix-update-test ") as directory:
    root = Path(directory)
    checkout = root / "private checkout"
    checkout.mkdir()
    expression = (
        f"let baseline = builtins.getFlake {json.dumps('path:' + str(SOURCE))}; "
        f"cases = import {SOURCE}/tests/update-fixtures.nix "
        f"{{ inherit baseline; configDirectory = {json.dumps(str(checkout))}; }}; in "
    )
    evaluated = execute([
        "nix", "eval", "--impure", "--json", "--expr", expression + "{ "
        "inherit (cases) evaluation; "
        "paths = builtins.mapAttrs (_: value: value.outPath) "
        "(builtins.removeAttrs cases [ \"evaluation\" ]); }",
    ])
    assert evaluated.returncode == 0, evaluated.stderr
    fixtures = json.loads(evaluated.stdout)
    assert all(fixtures["evaluation"].values()), fixtures["evaluation"]
    built = execute([
        "nix", "build", "--impure", "--no-link", "--expr",
        expression + "[ cases.success cases.failure cases.pipelineFailure ]",
    ])
    assert built.returncode == 0, built.stderr

    target = checkout / "files/git/config"
    target.parent.mkdir(parents=True)
    unrelated = checkout / "files/keep.txt"
    unrelated.write_text("keep me\n")
    external = root / "symlink-target"
    external.write_text("do not overwrite\n")

    for name, output in fixtures["paths"].items():
        target.write_text("original\n")
        if name == "success":
            target.unlink()
            target.symlink_to(external)
        result = execute([str(Path(output) / "bin/nix-config-update")])
        staging = Path((checkout / "staging-path").read_text().strip())
        assert not staging.exists(), f"staging leaked after {name}"
        if name == "success":
            assert result.returncode == 0, result.stderr
            assert (checkout / "order").read_text() == "first\nsecond\n"
            expected = (
                f"# This file is generated automatically by Fixture CLI in {checkout}.\n"
                "# Do not edit manually. Change the generating module and run dr update.\n"
                "new snapshot\n"
            )
            assert target.read_text() == expected
            assert not target.is_symlink()
            assert external.read_text() == "do not overwrite\n"
            docker = checkout / "files/docker/config.json"
            assert json.loads(docker.read_text()) == {"credsStore": "fixture"}
            assert (docker.parent / "README.md").exists()
        else:
            assert result.returncode != 0, f"{name} did not fail"
            assert target.read_text() == "original\n", "failed generation was published"
            assert not (checkout / "unexpected").exists(), "ran a step after failure"
        assert unrelated.read_text() == "keep me\n"

    # Replace external commands with stubs; no flake update, sudo or activation.
    commands = root / "commands"
    commands.mkdir()
    log = root / "commands.log"
    for name in ("nix", "sudo", "hook"):
        command = commands / name
        command.write_text(
            "#!/bin/sh\n"
            f"printf '{name}' >> \"$TEST_LOG\"\n"
            "printf ' <%s>' \"$@\" >> \"$TEST_LOG\"\n"
            "printf '\\n' >> \"$TEST_LOG\"\n"
            + {
                "nix": 'exit "${NIX_EXIT:-0}"\n',
                "hook": 'exit "${HOOK_EXIT:-0}"\n',
                "sudo": 'if [ "$2" = build ]; then exit "${BUILD_EXIT:-0}"; fi\n',
            }[name]
        )
        command.chmod(0o755)

    flake = "path:" + str(checkout)
    wrapper = SOURCE / "files/zsh/darwin-rebuild.zsh"
    hook = commands / "hook"

    def dispatch(arguments, *, runner=True, reset=False, **failures):
        log.write_text("")
        environment = os.environ | {
            "PATH": str(commands) + os.pathsep + os.environ["PATH"],
            "TEST_LOG": str(log),
            "NIX_EXIT": "0", "HOOK_EXIT": "0", "BUILD_EXIT": "0",
        } | failures
        script = 'source "$1" "$2" "$3"; shift 3; dr "$@"'
        if reset:
            script = 'source "$1" "$2" "$3"; source "$1" "$2"; shift 3; dr "$@"'
        result = execute([
            "/bin/zsh", "-f", "-c", script, "test", str(wrapper), flake,
            str(hook) if runner else "", *arguments,
        ], env=environment)
        return result, log.read_text().splitlines()

    update = f"nix <flake> <update> <--flake> <{flake}>"
    build = f"sudo <darwin-rebuild> <build> <--flake> <{flake}#update>"
    switch = f"sudo <darwin-rebuild> <switch> <--flake> <{flake}#update>"
    result, lines = dispatch(["update"])
    assert result.returncode == 0, result.stderr
    assert lines == [update, "hook <>", build, switch], lines
    for kwargs in ({"runner": False}, {"reset": True}):
        result, lines = dispatch(["update"], **kwargs)
        assert result.returncode == 0 and lines == [update, build, switch], lines

    for failure, expected in (
        ("NIX_EXIT", [update]),
        ("HOOK_EXIT", [update, "hook <>"]),
        ("BUILD_EXIT", [update, "hook <>", build]),
    ):
        result, lines = dispatch(["update"], **{failure: "7"})
        assert result.returncode == 7 and lines == expected, (result, lines)

    for action in ("build", "switch"):
        result, lines = dispatch([action])
        assert result.returncode == 0
        assert lines == [f"sudo <darwin-rebuild> <--flake> <{flake}#current> <{action}>"], lines
    result, lines = dispatch(["update", "unexpected"])
    assert result.returncode == 2 and not lines

print("Passed: DAG validation, staged generation, headers, failure handling, cleanup and dr dispatch.")
