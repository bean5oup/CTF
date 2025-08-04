import asyncio
import fcntl
import os
import shutil
import signal
import subprocess

import aiohttp
import yaml

from web3.eth import Eth
from storage import Storage
from util import *

__all__ = ("AnvilInstance",)

ANVIL_PATH = shutil.which("anvil")
ANVIL_VERSION_STR = "anvil/v1.0.0"
CONFIG = yaml.safe_load(open("config.yaml", "r"))
FLAG = open(CONFIG["flag_path"], "r").read()
WORKDIR = "/tmp/workdir"
PR_SET_PDEATHSIG = 1

os.umask(0o077)
try:
    shutil.rmtree(WORKDIR)
except FileNotFoundError:
    pass
os.mkdir(WORKDIR)
os.chmod(WORKDIR, 0o711)


class AnvilNotRunningError(Exception):
    pass


class AnvilInstance:
    @property
    def rpc_url(self):
        port = self.storage.port
        assert port != 0
        return f"http://127.0.0.1:{port}/"

    def get_environ(self):
        env_data_capitalized = {k.upper(): v for k, v in self.storage.env.items()}
        environ = (
            os.environ
            | env_data_capitalized
            | {
                "RPC_URL": self.rpc_url,
                "WS_RPC_URL": f"ws://127.0.0.1:{self.storage.port}/",
            }
        )
        return environ

    def __init__(self):
        self._base_path = WORKDIR
        self.storage = Storage()

    async def ready(self, start_if_not=False):
        with open(self._base_path + "/status", "a+") as lock_f:
            lock_f.seek(0, os.SEEK_SET)
            try:
                fcntl.flock(lock_f, fcntl.LOCK_EX | fcntl.LOCK_NB)
                os.ftruncate(lock_f.fileno(), 0)
                if not start_if_not:
                    return False
            except OSError:
                # Anvil is running. Is it ready?
                return lock_f.read(6) == "READY\n"

            # start...
            if self.storage.port == 0:
                self.storage.port = assign_port()
            self.storage.solved = False
            os.set_inheritable(lock_f.fileno(), True)
            await self._start(lock_f)
            return True

    def _run_anvil(self, lock_f):
        port = self.storage.port
        argv = [ANVIL_PATH, "--port", str(port)]

        if "anvil-options" in CONFIG:
            options = CONFIG["anvil-options"]
            parsed = []
            if isinstance(options, list):
                for anvil_opt in CONFIG.get("anvil-options", []):
                    if isinstance(anvil_opt, dict):
                        if "name" in anvil_opt:
                            name = anvil_opt["name"]
                            value = anvil_opt.get("value", None)
                        else:
                            assert (
                                len(anvil_opt) == 1
                            ), "There must be only one key-value pair in each item of anvil-options"
                            name, value = list(anvil_opt.items())[0]
                    else:
                        name = anvil_opt
                        value = None
                    parsed.append([name, value])

            elif isinstance(options, dict):
                parsed = list(options.items())
            else:
                assert False, "anvil-options must be either list of dicts or dict"

            for name, value in parsed:
                if len(name) == 1:
                    argv.append(f"-{name}")
                else:
                    argv.append(f"--{name}")
                if value is not None:
                    argv.append(str(value))

        # Start with no accounts (`-a 0`), if the option is not given
        if "-a" not in argv or "--accounts" not in argv:
            argv += ["-a", "0"]

        uid = os.getuid()
        if uid == 0:
            uid = 30000 + port - 1024

        def before_execve():
            import ctypes
            from ctypes.util import find_library

            os.closerange(0, lock_f.fileno() - 1)

            # Make anvil dies when uvicorn got killed
            libc = ctypes.CDLL(find_library("c"))
            libc.prctl(PR_SET_PDEATHSIG, signal.SIGKILL, 0, 0, 0)

            os.nice(10)

        proc = subprocess.Popen(
            argv,
            preexec_fn=before_execve,
            start_new_session=True,
            user=uid,
            close_fds=False,
        )
        return proc.pid

    async def _wait_until_anvil_running(self):
        for _ in range(100):
            await asyncio.sleep(0.5)
            try:
                result = await self.get_client_version()
            except aiohttp.client_exceptions.ClientResponseError:
                continue
            except aiohttp.client_exceptions.ClientConnectorError:
                # This needs to handle the forked RPC:
                # don't know why anvil does not expose any ports until connecting with the forked RPC
                # hence the request raises the connection error :(
                continue

            if result == ANVIL_VERSION_STR:
                break

        assert (await self.get_client_version()) == ANVIL_VERSION_STR

    def _run_subprocess(self, argv, environ, cwd):
        uid = os.getuid()
        if uid == 0:
            uid = 30000 + self.storage.port - 1024

        def before_execve():
            import ctypes
            from ctypes.util import find_library

            # Make anvil dies when uvicorn got killed
            libc = ctypes.CDLL(find_library("c"))
            libc.prctl(PR_SET_PDEATHSIG, signal.SIGKILL, 0, 0, 0)

        proc = subprocess.Popen(
            argv,
            preexec_fn=before_execve,
            start_new_session=True,
            user=uid,
            env=environ,
            cwd=cwd,
        )
        return proc.pid

    async def _start(self, lock_f):
        pid = self._run_anvil(lock_f)
        self.storage.pid = pid

        await self._wait_until_anvil_running()
        await self._setup_environment()

        # Setup env variables for subprocesses
        environ = self.get_environ()

        # Run subprocesses
        subproc_pids = []
        for proc_info in CONFIG.get("subprocesses", []):
            command = proc_info["command"]
            cwd = proc_info["cwd"]

            argv = command.strip().split()
            argv = [shutil.which(argv[0]), *argv[1:]]

            pid = self._run_subprocess(argv, environ, cwd)
            subproc_pids.append(pid)
        self.storage.subproc_pids = subproc_pids

        # Genesis block starts from 0
        self.storage.last_event_checked_block = 0
        lock_f.write("READY\n")

    async def _setup_environment(self):
        env_data = dict()

        # Generate owner/user address
        for account in CONFIG.get("accounts", []):
            name = account["name"]
            balance = account["balance"]

            key_pair = Eth.account.create()
            await self.set_balance(key_pair.address, balance)

            env_data[f"{name}_address"] = key_pair.address
            env_data[f"{name}_private_key"] = key_pair.key.hex()
            os.environ[f"{name}_private_key"] = key_pair.key.hex()

        os.environ["RPC_URL"] = self.rpc_url
        
        # Deploy contracts
        for deployment in CONFIG.get("deployments", []):
            if "is_script" in deployment:
                # do script stuff
                name = deployment["name"]
                path = deployment["path"]
                target_contract = deployment["target_contract"]
                private_key = deployment["private_key"]
                if private_key in env_data:  # replace
                    private_key = env_data[private_key]

                contract_address = await deploy_contract_via_script(
                    self.rpc_url,
                    path,
                    private_key,
                    target_contract
                 )
                env_data[f"{name}_address"] = contract_address
                continue

            name = deployment["name"]
            path = deployment["path"]
            gas_limit = deployment.get("gas_limit", None)
            value = deployment.get("value", None)
            constructor_args = deployment.get("constructor_args", [])
            if isinstance(constructor_args, str):
                constructor_args = [constructor_args]
            for i in range(len(constructor_args)):
                arg = constructor_args[i]
                if arg in env_data:  # replace
                    constructor_args[i] = env_data[arg]
                elif arg.startswith("randbytes:"):
                    bytelen = int(arg.replace("randbytes:", ""))
                    constructor_args[i] = os.urandom(bytelen).hex()

            private_key = deployment["private_key"]
            if private_key in env_data:  # replace
                private_key = env_data[private_key]

            contract_address = await deploy_contract(
                self.rpc_url,
                path,
                private_key,
                gas_limit=gas_limit,
                value=value,
                constructor_args=constructor_args,
            )
            env_data[f"{name}_address"] = contract_address

        # Save global data
        self.storage.env = env_data

    def info(self):
        if self.storage.pid == 0:
            raise AnvilNotRunningError
        env = self.storage.env
        return {key: env[key] for key in CONFIG.get("exposed", [])}

    def reset(self):
        pid = self.storage.pid
        if pid == 0:
            return

        subproc_pids = self.storage.subproc_pids
        pids = [pid] + subproc_pids

        self.storage.destroyall()

        for pid in pids:
            try:
                os.kill(pid, signal.SIGKILL)
                os.waitpid(pid, 0)
            except (ProcessLookupError, ChildProcessError):
                pass

    # This is a wrapper of _rpc_json, that only allows standard methods
    async def rpc(self, data):
        if self.storage.pid == 0:
            raise AnvilNotRunningError
        method = data["method"]
        if method == "eth_sendUnsignedTransaction" or method == "eth_sendTransaction" or not any(
            method.startswith(prefix) for prefix in ["eth_", "web3_", "net_"]
        ):
            raise PermissionError
        return await self._rpc_json(data)

    async def _rpc_internal(self, method, params=[], id_=1):
        if self.storage.pid == 0:
            raise AnvilNotRunningError
        json_data = {"jsonrpc": "2.0", "method": method, "params": params, "id": id_}
        return await self._rpc_json(json_data)

    async def _rpc_json(self, data):
        async with aiohttp.ClientSession() as session:
            async with session.post(self.rpc_url, json=data) as resp:
                return await resp.json()

    async def get_client_version(self):
        ret = await self._rpc_internal("web3_clientVersion")
        return ret["result"]

    async def get_latest_block(self):
        ret = await self._rpc_internal("eth_blockNumber")
        return int(ret["result"], 16)

    async def set_balance(self, address, value):
        balance = to_wei(value) if isinstance(value, str) else value
        await self._rpc_internal("anvil_setBalance", [address, hex(balance)])

    async def get_flag(self):
        if self.storage.solved:
            return {"message": FLAG}

        with open(self._base_path + "/check_solve_lock", "w+") as lock_f:
            try:
                fcntl.flock(lock_f, fcntl.LOCK_EX | fcntl.LOCK_NB)
            except OSError:
                return {"error": "server is checking your transactions"}

            last_check_block = self.storage.last_event_checked_block
            if (await self.get_latest_block()) <= last_check_block:
                return {"message": "No more blocks to check"}

            self.storage.solved = await check_solved(self.get_environ())
            self.storage.last_event_checked_block = await self.get_latest_block()

            if self.storage.solved:
                return {"message": FLAG}
            else:
                return {"message": "Failed"}
