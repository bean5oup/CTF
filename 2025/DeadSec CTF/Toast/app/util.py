import asyncio
import os
import shutil
import socket

import yaml

from web3 import Web3

CONFIG = yaml.safe_load(open("config.yaml", "r"))
FORGE_PATH = shutil.which("forge")
FORGE_PROJECT_DIR = os.environ.get("FORGE_PROJECT_DIR", "/forge_project")


def assign_port() -> int:
    s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    s.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)

    for port in range(1024, 1024 + 30000):
        try:
            s.bind(("127.0.0.1", port))
            s.close()
            return port
        except socket.error:
            continue
    raise Exception("assign_port: failed")


def to_wei(inp: str) -> int:
    inp = inp.lower().strip()

    for i, ch in enumerate(inp):
        if 48 <= ord(ch) <= 59 or ch == ".":
            continue
        else:
            return Web3.to_wei(inp[:i], inp[i:].strip())


async def deploy_contract(
    rpc_url: str,
    contract_path: str,
    private_key: str,
    gas_limit: int | str = None,
    value: str = None,
    constructor_args: list[str] = None,
):
    gas_limit_args = ["--gas-limit", str(gas_limit)] if gas_limit else []
    value_args = ["--value", value] if value else []
    constructor_args = (
        ["--constructor-args", *constructor_args] if constructor_args else []
    )

    subprocess = await asyncio.create_subprocess_exec(
        FORGE_PATH,
        "create",
        "--rpc-url",
        rpc_url,
        "--legacy",
        "--broadcast",
        "--private-key",
        private_key,
        *gas_limit_args,
        *value_args,
        contract_path,
        *constructor_args,
        stdout=asyncio.subprocess.PIPE,
        cwd=FORGE_PROJECT_DIR,
    )
    stdout, _ = await subprocess.communicate()
    contract_address = stdout.split(b"Deployed to: ")[1].split(b"\n")[0].decode("ascii")
    return contract_address

async def deploy_contract_via_script(
    rpc_url: str,
    contract_path: str,
    private_key: str,
    target_contract: str,
):
    subprocess = await asyncio.create_subprocess_exec(
        FORGE_PATH,
        "script",
        contract_path,
        "--rpc-url",
        rpc_url,
        "--ffi",
        "--slow",
        "--legacy",
        "--broadcast",
        "--private-key",
        private_key,
        "--target-contract",
        target_contract,
        stdout=asyncio.subprocess.PIPE,
        cwd=FORGE_PROJECT_DIR,
    )
    stdout, _ = await subprocess.communicate()
    contract_address = stdout.split(b"Deployed to: ")[1].split(b"\n")[0].decode("ascii")
    return contract_address


async def check_solved(environ: dict[str, str]):
    verifier = CONFIG["verifier"]
    if isinstance(verifier, str):
        argv = CONFIG["verifier"].strip().split()
        argv = [shutil.which(argv[0]), *argv[1:]]
    else:
        argv = verifier

    proc = await asyncio.create_subprocess_exec(
        *argv,
        env=environ,
        cwd=FORGE_PROJECT_DIR,
    )
    await proc.wait()
    # It is correct only if returncode is 0
    solved = not proc.returncode

    return solved
